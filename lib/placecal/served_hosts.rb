# frozen_string_literal: true

require 'erb'
require 'yaml'

module PlaceCal
  # The host names this deploy's proxy routes to PlaceCal (Kamal's proxy.hosts),
  # so whether a site's domain is served is read from deploy config, not stored.
  class ServedHosts
    class Missing < StandardError; end

    class << self
      # @return [ServedHosts] config.x.served_hosts when set, else the
      #   current environment's Kamal destination file
      def current
        @current ||= new(configured_hosts || from_deploy_file(Rails.env))
      end

      def reset!
        @current = nil
      end

      # Only the destination file is read: base config/deploy.yml defines no
      # hosts, and its ERB shells out to git, which the runtime image lacks.
      #
      # @param env [String] Kamal destination, which matches the Rails env
      # @return [Array<String>] proxy hosts, [] when there is no such file
      def from_deploy_file(env, root: Rails.root)
        path = root.join("config/deploy.#{env}.yml")
        return [] unless path.exist?

        # Statement tags only load Kamal's secrets files, which the app must not read.
        template = path.read.gsub(/<%(?!=).*?%>/m, '')
        config = YAML.safe_load(ERB.new(template).result, aliases: true) || {}
        proxy = config['proxy'] || {}
        Array(proxy['hosts'] || proxy['host']).compact.map(&:to_s)
      end

      private

      def configured_hosts
        hosts = Rails.configuration.x.served_hosts
        Array(hosts).map(&:to_s) if hosts.is_a?(Array) || hosts.is_a?(String)
      end
    end

    attr_reader :patterns

    # @param patterns [Array<String>] host names, or *.example.org wildcards
    def initialize(patterns)
      @patterns = Array(patterns).map { |pattern| pattern.to_s.strip.downcase }.compact_blank.uniq.freeze
    end

    # Raises in deployed environments so a missing host list fails the boot
    # instead of quietly moving every custom domain back to its subdomain.
    def verify!
      raise Missing, "No proxy hosts found in config/deploy.#{Rails.env}.yml" if patterns.empty?

      self
    end

    # Wildcards match a single label, as kamal-proxy's do.
    #
    # @param host [String]
    # @return [Boolean]
    def serves?(host)
      host = host.to_s.downcase
      return false if host.empty?

      patterns.any? do |pattern|
        if pattern.start_with?('*.')
          suffix = pattern.delete_prefix('*')
          label = host.delete_suffix(suffix)
          host.end_with?(suffix) && label.present? && label.exclude?('.')
        else
          pattern == host
        end
      end
    end
  end
end
