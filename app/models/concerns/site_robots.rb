# frozen_string_literal: true

module SiteRobots
  extend ActiveSupport::Concern

  # @return [String] robots.txt content, blocking crawlers if unpublished
  def robots
    if is_published?
      self.class.published_robots
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
      published_robots
    end

    # @return [String] the permissive robots.txt template plus sitemap reference
    def published_robots
      "#{robots_config}\nSitemap: #{self::DIRECTORY_URL}/sitemap.xml\n"
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
