# frozen_string_literal: true

module SiteRobots
  extend ActiveSupport::Concern

  # @return [String] robots.txt content, blocking crawlers if unpublished
  def robots
    if is_published?
      # A site advertises its own sitemap, not the directory's. The directory's
      # sitemap lists nothing under this site's hostname.
      self.class.published_robots(directory_url.chomp('/'))
    else
      <<~TXT
        #{self.class.robots_config}
        User-agent: *
        Disallow: /
      TXT
    end
  end

  class_methods do
    # robots.txt for the nationwide directory at the apex domain. The directory
    # has no Site row and is always publicly crawlable.
    # @return [String]
    def directory_robots
      published_robots(self::DIRECTORY_URL)
    end

    # @param base_url [String] host the sitemap is served from, no trailing slash
    # @return [String] the permissive robots.txt template plus sitemap reference
    def published_robots(base_url = self::DIRECTORY_URL)
      "#{robots_config}\nSitemap: #{base_url}/sitemap.xml\n"
    end

    # @return [String] contents of the environment's robots.txt template
    def robots_config
      File.read(Rails.root.join("config/robots/#{robots_config_filename}"))
    end

    # Selects the robots.txt template based on ALLOW_AI_SEARCH_BOTS env var.
    # In production, defaults to allowing search-AI bots (permissive template).
    # Set ALLOW_AI_SEARCH_BOTS=false to block all AI bots (strict template).
    def robots_config_filename
      if Rails.env.production? && ENV.fetch('ALLOW_AI_SEARCH_BOTS', 'true') == 'false'
        'robots.production.strict.txt'
      else
        "robots.#{Rails.env}.txt"
      end
    end
  end
end
