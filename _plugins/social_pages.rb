# Co-written with Claude

Jekyll::Hooks.register :posts, :post_write do |post|
  # no-op; generation handled at site level
end

module Jekyll
  class SocialPageGenerator < Generator
    safe true

    def generate(site)
      wire = site.collections["wire"]
      return unless wire

      wire.docs.each do |post|
        social = PageWithoutAFile.new(site, site.source, "", "index.html")
        social.data = post.data.merge(
          "layout"    => "social",
          "permalink" => "/social#{post.url}"
        )
        social.content = post.content
        site.pages << social
      end
    end
  end
end