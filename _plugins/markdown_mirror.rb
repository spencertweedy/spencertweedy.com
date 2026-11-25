# Co-written with Claude
#
# Markdown mirror for BonBon and other Markdown-web browsers.
#
# For every Markdown-sourced page (wire, observations, newsletters, and the
# .md files in pages/), writes a .md file beside the HTML output:
#
#   /wire/2026/09/04/starship/index.html  ->  /wire/2026/09/04/starship/index.md
#   /now.html                             ->  /now.md
#
# Also writes a generated home page (/index.md), a wire archive (/wire.md),
# and the BonBon site files in /.well-known/ (toc.opml, bonbon.json), plus
# per-section tables of contents in /wire/.well-known/ and
# /observations/.well-known/.
#
# Spec: https://github.com/scripting/bonBon/blob/main/docs/bonbonSkillFromClaude.md

require "cgi"
require "time"
require "yaml"

module MarkdownMirror
  COLLECTIONS = %w[wire observations newsletters].freeze
  SKIP_PAGE_URLS = %w[/404.html /observations/404.html].freeze
  HOME_RECENT = 30

  # Holds Liquid-rendered Markdown, keyed by the doc's output URL.
  @sources = {}

  class << self
    attr_reader :sources

    def reset
      @sources = {}
    end

    def mirrored_collection?(doc)
      doc.respond_to?(:collection) && COLLECTIONS.include?(doc.collection.label)
    end

    def mirrored_page?(page)
      page.is_a?(Jekyll::Page) && !page.is_a?(Jekyll::PageWithoutAFile) &&
        %w[.md .markdown].include?(page.ext) && !SKIP_PAGE_URLS.include?(page.url)
    end

    # /foo/ -> /foo/index.md, /now -> /now.md, /now.html -> /now.md
    def md_url(url)
      return "#{url}index.md" if url.end_with?("/")
      url.sub(/\.html\z/, "") + ".md"
    end

    # Render Liquid but leave Markdown as Markdown. Includes are dropped: they
    # are HTML widgets (carousels, embeds) that BonBon would strip anyway.
    def render_liquid(item, payload)
      site = item.site
      text = item.content.gsub(/\{%-?\s*include\s.*?-?%\}/m, "")
      template = site.liquid_renderer.file("#{item.path}#md-mirror").parse(text)
      template.render!(payload, registers: { site: site, page: payload["page"] })
    rescue StandardError => e
      Jekyll.logger.warn "Markdown mirror:", "Liquid failed for #{item.relative_path}: #{e.message}"
      item.content.gsub(/\{%.*?%\}/m, "").gsub(/\{\{.*?\}\}/m, "")
    end

    def attr(tag, name)
      tag[/\b#{name}\s*=\s*"([^"]*)"/i, 1] || tag[/\b#{name}\s*=\s*'([^']*)'/i, 1]
    end

    # BonBon throws HTML away. Turn the handful of tags this site uses into
    # Markdown so nothing meaningful is lost, then drop the rest.
    def html_to_markdown(text)
      text = text.gsub(/<(script|style|iframe)\b.*?<\/\1>/mi, "")

      # <figure> / <picture> blocks become a lone image paragraph; BonBon
      # centers it and shows the alt text as a caption.
      text = text.gsub(/<figure\b.*?<\/figure>/mi) do |fig|
        img = fig[/<img\b[^>]*>/i]
        next "" unless img
        caption = fig[/<figcaption[^>]*>(.*?)<\/figcaption>/mi, 1]
        alt = [attr(img, "alt"), caption && strip_tags(caption)].compact.reject(&:empty?).join(". ")
        "\n\n![#{alt.gsub(/[\[\]]/, "")}](#{attr(img, "src")})\n\n"
      end
      text = text.gsub(/<picture\b.*?<\/picture>/mi) do |pic|
        img = pic[/<img\b[^>]*>/i]
        img ? "![#{attr(img, "alt")}](#{attr(img, "src")})" : ""
      end
      text = text.gsub(/<img\b[^>]*>/i) { |img| "![#{attr(img, "alt")}](#{attr(img, "src")})" }

      text = text.gsub(/<a\b([^>]*)>(.*?)<\/a>/mi) do
        href = attr(Regexp.last_match(1), "href")
        label = strip_tags(Regexp.last_match(2))
        href ? "[#{label}](#{href})" : label
      end
      text = text.gsub(/<(em|i)>(.*?)<\/\1>/mi, '*\2*')
      text = text.gsub(/<(strong|b)>(.*?)<\/\1>/mi, '**\2**')
      text = text.gsub(/<br\s*\/?>/i, "  \n")
      text = text.gsub(/<\/?(p|div)\b[^>]*>/i, "\n")
      text = strip_tags(text)

      # Kramdown attribute lists ({: .class}) mean nothing outside kramdown.
      text = text.gsub(/^\s*\{:[^}\n]*\}\s*$\n?/, "").gsub(/\{:[^}\n]*\}/, "")
      text.gsub(/\n{3,}/, "\n\n").strip
    end

    def strip_tags(text)
      text.gsub(/<\/?[a-z][a-z0-9-]*\b[^>]*>/i, "")
    end

    # Point internal links at their .md mirrors so readers stay in BonBon.
    def rewrite_links(text, url_map, site_url)
      host = site_url.sub(%r{\Ahttps?://}, "")
      text.gsub(/(\]\()([^)\s]+)/) do
        prefix, href = Regexp.last_match(1), Regexp.last_match(2)
        path = href.sub(%r{\Ahttps?://(www\.)?#{Regexp.escape(host)}}, "")
        next "#{prefix}#{href}" unless path.start_with?("/")
        base, frag = path.split("#", 2)
        target = url_map[base] || url_map[base.sub(/\.html\z/, "")] ||
                 url_map[base.end_with?("/") ? base : "#{base}/"]
        target ? "#{prefix}#{target}#{frag ? "##{frag}" : ""}" : "#{prefix}#{href}"
      end
    end

    def rfc822(date)
      date&.to_time&.utc&.httpdate
    end

    def front_matter(fields)
      clean = fields.reject { |_, v| v.nil? || v.to_s.strip.empty? }
      YAML.dump(clean.transform_keys(&:to_s)).sub(/\A---\s*\n/, "---\n") + "---\n\n"
    end

    # Observations are filed under the day they describe (datestamp), which
    # is often earlier than the day they were posted (date).
    def day_of(doc)
      stamp = doc.data["datestamp"]
      stamp ? Date.strptime(stamp.to_s, "%Y%m%d") : doc.date
    end

    def human_date(date)
      date.strftime("%A, %-d %b %Y")
    end

    def write(dest, url, body)
      path = File.join(dest, Jekyll::URL.unescape_path(url))
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, body)
    end

    def opml(title, body)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <head>
            <title>#{CGI.escapeHTML(title)}</title>
            <dateModified>#{Time.now.utc.httpdate}</dateModified>
          </head>
          <body>
        #{body}
          </body>
        </opml>
      XML
    end

    def link_node(text, url, indent)
      %(#{"  " * indent}<outline text="#{CGI.escapeHTML(text.to_s)}" type="link" url="#{CGI.escapeHTML(url)}"/>)
    end

    # year > month > entries, oldest first, like a blog calendar.
    def dated_outline(entries, indent)
      entries.group_by { |e| e[:date].year }.sort.flat_map do |year, by_year|
        months = by_year.group_by { |e| e[:date].month }.sort.flat_map do |month, items|
          ["#{"  " * (indent + 1)}<outline text=\"#{Date::MONTHNAMES[month]} #{year}\">",
           *items.map { |e| link_node(e[:text], e[:url], indent + 2) },
           "#{"  " * (indent + 1)}</outline>"]
        end
        ["#{"  " * indent}<outline text=\"#{year}\">", *months, "#{"  " * indent}</outline>"]
      end.join("\n")
    end

    def generate(site)
      dest = site.dest
      site_url = site.config["url"].to_s
      author = site.config["author"]

      docs = COLLECTIONS.flat_map { |label| site.collections[label]&.docs.to_a }
      pages = site.pages.select { |p| mirrored_page?(p) }
      items = (docs + pages).select { |i| sources.key?(i.url) }

      url_map = items.to_h { |i| [i.url, md_url(i.url)] }
      url_map["/"] = "/index.md"
      url_map["/wire"] = "/wire.md"

      # Explicit prev/next within each collection, in the collection's order.
      neighbors = {}
      COLLECTIONS.each do |label|
        list = site.collections[label]&.docs.to_a.select { |d| sources.key?(d.url) }
        list.each_with_index do |d, i|
          neighbors[d.url] = [i.positive? ? list[i - 1] : nil, list[i + 1]]
        end
      end

      items.each do |item|
        data = item.data
        date = data["date"] if data["date"].respond_to?(:strftime)
        prev_doc, next_doc = neighbors[item.url]
        fields = {
          "title" => data["title"],
          "description" => data["description"],
          "author" => author,
          "pubDate" => rfc822(date),
          "link" => data["link"],
          "urlPrev" => prev_doc && md_url(prev_doc.url),
          "urlNext" => next_doc && md_url(next_doc.url),
        }
        head = +"# {{page.title}}\n\n"
        head << "#{human_date(date)}\n\n" if date && !data["datestamp"]
        body = rewrite_links(html_to_markdown(sources[item.url]), url_map, site_url)
        write(dest, md_url(item.url), front_matter(fields) + head + body + "\n")
      end

      wire = site.collections["wire"]&.docs.to_a.select { |d| sources.key?(d.url) }
      obs = site.collections["observations"]&.docs.to_a.select { |d| sources.key?(d.url) }
      news = site.collections["newsletters"]&.docs.to_a.select { |d| sources.key?(d.url) }
      wire_entry = ->(d) { "- [#{d.data["title"]}](#{md_url(d.url)}) — #{d.date.strftime("%-d %b %Y")}" }

      # Home page.
      home = front_matter("title" => author, "description" => site.config["description"], "author" => author)
      home << "# {{page.title}}\n\n#{site.config["description"]}\n\n"
      home << "This is the Markdown edition of [spencertweedy.com](#{site_url}/).\n\n"
      home << pages.select { |p| p.url.count("/") == 1 }.sort_by(&:url)
                   .map { |p| "[#{p.data["title"]}](#{md_url(p.url)})" }.join(" · ") + "\n\n"
      home << "## Recent posts\n\n" << wire.last(HOME_RECENT).reverse.map(&wire_entry).join("\n")
      home << "\n\n[All posts](/wire.md)\n"
      if obs&.any?
        home << "\n## Observations\n\nA daily list blog, #{day_of(obs.first).year}–#{day_of(obs.last).year}. "
        home << "Latest: [#{obs.last.data["title"]}](#{md_url(obs.last.url)}).\n"
      end
      write(dest, "/index.md", home)

      # Wire archive.
      archive = front_matter("title" => "Wire", "author" => author)
      archive << "# {{page.title}}\n\n"
      wire.reverse.group_by { |d| d.date.year }.each do |year, list|
        archive << "## #{year}\n\n" << list.map(&wire_entry).join("\n") << "\n\n"
      end
      write(dest, "/wire.md", archive)

      # Tables of contents.
      to_entry = ->(d) { { date: day_of(d), text: d.data["title"], url: "#{site_url}#{md_url(d.url)}" } }
      write(dest, "/wire/.well-known/toc.opml",
            opml("Wire", dated_outline(wire.map(&to_entry), 2)))
      write(dest, "/observations/.well-known/toc.opml",
            opml("Observations", dated_outline(obs.map(&to_entry), 2)))

      top_pages, obs_pages = pages.sort_by(&:url).partition { |p| p.url.count("/") == 1 }
      top = [link_node("Home", "#{site_url}/index.md", 2)]
      top_pages.each { |p| top << link_node(p.data["title"], "#{site_url}#{md_url(p.url)}", 2) }
      top << "    <outline text=\"Wire\">"
      top << link_node("All posts", "#{site_url}/wire.md", 3)
      top << %(      <outline type="include" url="#{site_url}/wire/.well-known/toc.opml"/>)
      top << "    </outline>"
      top << "    <outline text=\"Observations\">"
      obs_pages.each { |p| top << link_node(p.data["title"], "#{site_url}#{md_url(p.url)}", 3) }
      top << %(      <outline type="include" url="#{site_url}/observations/.well-known/toc.opml"/>)
      top << "    </outline>"
      if news&.any?
        top << "    <outline text=\"Observations newsletters\">"
        news.each { |d| top << link_node(d.data["title"], "#{site_url}#{md_url(d.url)}", 3) }
        top << "    </outline>"
      end
      write(dest, "/.well-known/toc.opml", opml(site.config["title"].to_s, top.join("\n")))

      write(dest, "/.well-known/bonbon.json", JSON.pretty_generate("urlMirrorOf" => site_url) + "\n")

      Jekyll.logger.info "Markdown mirror:", "wrote #{items.size} pages plus index, archive and tables of contents"
    end
  end
end

Jekyll::Hooks.register :site, :after_reset do |_site|
  MarkdownMirror.reset
end

Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  next unless MarkdownMirror.mirrored_collection?(doc)
  MarkdownMirror.sources[doc.url] = MarkdownMirror.render_liquid(doc, payload)
end

Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  next unless MarkdownMirror.mirrored_page?(page)
  MarkdownMirror.sources[page.url] = MarkdownMirror.render_liquid(page, payload)
end

Jekyll::Hooks.register :site, :post_write do |site|
  MarkdownMirror.generate(site)
end
