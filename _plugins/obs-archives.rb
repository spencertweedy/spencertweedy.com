require "jekyll"

module Jekyll
  class Archives < Jekyll::Generator
    safe true

    DEFAULTS = {
      "layout"     => "archive",
      "enabled"    => [],
      "permalinks" => {
        "year"     => "/:year/",
        "month"    => "/:year/:month/",
      },
    }.freeze

    def initialize(config = {})
      archives_config = config.fetch("obs-archives", {})
      if archives_config.is_a?(Hash)
        @config = Utils.deep_merge_hashes(DEFAULTS, archives_config)
      else
        @config = nil
        Jekyll.logger.warn "Archives:", "Expected a hash but got #{archives_config.inspect}"
        Jekyll.logger.warn "", "Archives will not be generated for this site."
      end
      @enabled = @config && @config["enabled"]
    end

    def generate(site)
      return if @config.nil?

      @site = site
      @posts = site.collections["observations"]
      @archives = []

      @site.config["obs-archives"] = @config

      read_dates
      @site.pages.concat(@archives)

      @site.config["observations-months"] = @archives
    end

    def read_dates
      years.each do |year, y_posts|
        append_enabled_date_type({ :year => year }, "year", y_posts)
        months(y_posts).each do |month, m_posts|
          append_enabled_date_type({ :year => year, :month => month }, "month", m_posts)
        end
      end
    end

    # Checks if archive type is enabled in config
    def enabled?(archive)
      @enabled == true || @enabled == "all" || (@enabled.is_a?(Array) && @enabled.include?(archive))
    end

    # Custom `post_attr_hash` method for years
    def years
      date_attr_hash(@posts.docs, "%Y")
    end

    # Custom `post_attr_hash` method for months
    def months(year_posts)
      date_attr_hash(year_posts, "%m")
    end

    private

    # Initialize a new Archive page and append to base array if the associated date `type`
    # has been enabled by configuration.
    #
    # meta  - A Hash of the year / month / day as applicable for date.
    # type  - The type of date archive.
    # posts - The array of posts that belong in the date archive.
    def append_enabled_date_type(meta, type, posts)
      @archives << Archive.new(@site, meta, type, posts) if enabled?(type)
    end

    # Custom `post_attr_hash` for date type archives.
    #
    # posts - Array of posts to be considered for archiving.
    # id    - String used to format post date via `Time.strptime` e.g. %Y, %m, etc.
    def date_attr_hash(posts, id)
      hash = Hash.new { |hsh, key| hsh[key] = [] }
      posts.each do |post|
        unless post.data["datestamp"].nil?
          # Convert the 'datestamp' string into a Ruby Date object
          parsed_time = Date.strptime(post.data["datestamp"], "%Y%m")

          # Format the Date object and add it into the hash
          hash[parsed_time.strftime(id)] << post
        end
      end
      hash.each_value { |posts| posts.sort!.reverse! }
      hash
    end
  end

  class Archive < Jekyll::Page
    attr_accessor :posts, :type, :slug

    # Attributes for Liquid templates
    ATTRIBUTES_FOR_LIQUID = %w(
      posts
      type
      title
      date
      name
      path
      url
      permalink
    ).freeze

    # Initialize a new Archive page
    #
    # site  - The Site object.
    # title - The name of the tag/category or a Hash of the year/month/day in case of date.
    #           e.g. { :year => 2014, :month => 08 } or "my-category" or "my-tag".
    # type  - The type of archive. Can be one of "year", "month", "day", "category", or "tag"
    # posts - The array of posts that belong in this archive.
    def initialize(site, title, type, posts)
      @site   = site
      @posts  = posts
      @type   = type
      @title  = title
      @config = site.config["obs-archives"]

      # Generate slug if tag or category
      # (taken from jekyll/jekyll/features/support/env.rb)
      @slug = Utils.slugify(title) if title.is_a? String

      # Use ".html" for file extension and url for path
      @ext  = File.extname(relative_path)
      @path = relative_path
      @name = File.basename(relative_path, @ext)

      @data = {
        "layout" => layout,
      }
      @content = ""
    end

    # The template of the permalink.
    #
    # Returns the template String.
    def template
      @config.dig("permalinks", type)
    end

    # The layout to use for rendering
    #
    # Returns the layout as a String
    def layout
      @config.dig("layouts", type) || @config["layout"]
    end

    # Returns a hash of URL placeholder names (as symbols) mapping to the
    # desired placeholder replacements. For details see "url.rb".
    def url_placeholders
      if @title.is_a? Hash
        @title.merge(:type => @type)
      else
        { :name => @slug, :type => @type }
      end
    end

    # The generated relative url of this page. e.g. /about.html.
    #
    # Returns the String url.
    def url
      @url ||= URL.new(
        :template     => template,
        :placeholders => url_placeholders,
        :permalink    => nil
      ).to_s
    rescue ArgumentError
      raise ArgumentError, "Template \"#{template}\" provided is invalid."
    end

    def permalink
      data&.is_a?(Hash) && data["permalink"]
    end

    # Produce a title object suitable for Liquid based on type of archive.
    #
    # Returns a String (for tag and category archives) and… something else for date archives
    def title
      if @title.is_a? Hash
        args = @title.values.map(&:to_i)
        date = Date.new(*args)

        @title = date.strftime("%B %Y")
        @title
      elsif @title.is_a? String
        @title
      end
    end

    # Produce a date object if a date-based archive
    #
    # Returns a Date.
    def date
      if @title.is_a? Hash
        args = @title.values.map(&:to_i)
        Date.new(*args)
      end
    end

    # Obtain the write path relative to the destination directory
    #
    # Returns the destination relative path String.
    def relative_path
      path = URL.unescape_path(url).gsub(%r!^\/!, "")
      path = File.join(path, "index.html") if url =~ %r!\/$!
      path
    end

    # Returns the object as a debug String.
    def inspect
      "#<Jekyll:Archive @type=#{@type} @title=#{@title} @data=#{@data.inspect}>"
    end
  end
end
