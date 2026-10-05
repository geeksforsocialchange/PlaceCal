# frozen_string_literal: true

require_relative 'theme'
require_relative 'theme_translation'

module PlaceCal
  # Registry that extensions (Rails engines) register into. Core knows
  # nothing about individual extensions: it only reads the registry.
  # See doc/extensions.md and #3368 (D1, D2).
  #
  # Core's built-in themes register through the same API at boot in
  # config/initializers/extensions.rb, so there is exactly one code path.
  module Extensions
    class UnknownTheme < KeyError; end

    # Route constraint for the `/:slug` theme-page catch-all
    # (config/initializers/site_page_routes.rb). Without it every unknown
    # single-segment path becomes a fully rendered 404: the whole public
    # before_action chain runs, the layout is built, and a scanner walking
    # /wp-login, /backup and the rest pays for all of it. With it, only a slug
    # some registered theme actually serves is recognised; everything else
    # stays a routing 404 that never reaches a controller.
    module ThemePage
      # @param request [ActionDispatch::Request]
      # @return [Boolean]
      def self.matches?(request)
        Extensions.page_slugs.include?(request.path_parameters[:slug])
      end
    end

    module_function

    # Register (or replace) a theme definition.
    #
    # @param name [Symbol, String]
    # @param core [Boolean] see PlaceCal::Theme#initialize
    # @yield [theme] the PlaceCal::Theme to configure
    # @return [PlaceCal::Theme]
    def register_theme(name, core: false)
      theme = Theme.new(name, core: core)
      yield theme if block_given?
      warn_on_reregistration(theme.name)
      registry[theme.name] = theme
      invalidate_page_slugs!
      theme
    end

    # Every page slug any registered theme serves, across all themes: the
    # router has one route for all of them and cannot know the site until the
    # request is in a controller. Computed from the registry and recomputed
    # whenever it changes, so the constraint costs a Set lookup per request.
    #
    # @return [Set<String>]
    def page_slugs
      @page_slugs ||= registry.each_value.flat_map { |theme| theme.pages.keys }.to_set
    end

    # Called from Theme#page and from every registry mutation.
    def invalidate_page_slugs!
      @page_slugs = nil
    end

    # Two extensions claiming the same theme name is a silent hijack: the last
    # one to boot wins and the other extension's sites change appearance. Say
    # so in the log. Specs replace registrations deliberately, so stay quiet
    # there.
    def warn_on_reregistration(name)
      return if Rails.env.test?
      return unless registry.key?(name)

      Rails.logger.warn(
        "PlaceCal::Extensions: theme #{name.inspect} was already registered; the previous definition has been replaced"
      )
    end
    private_class_method :warn_on_reregistration

    # @return [Array<PlaceCal::Theme>] core themes first, then extension
    #   themes, each group in registration order
    def themes
      core, extension = registry.values.partition(&:core?)
      core + extension
    end

    # @return [Array<String>]
    def theme_names
      themes.map(&:name)
    end

    # @param name [Symbol, String, nil]
    # @return [PlaceCal::Theme, nil]
    def find_theme(name)
      return nil if name.blank?

      registry[name.to_s]
    end

    # @param name [Symbol, String]
    # @return [PlaceCal::Theme]
    # @raise [UnknownTheme]
    def fetch_theme(name)
      find_theme(name) || raise(UnknownTheme, "no theme registered as #{name.inspect}")
    end

    # Empty the registry. For specs; pair with #snapshot / #restore.
    def reset!
      registry.clear
      invalidate_page_slugs!
    end

    # @return [Hash] a copy of the registry state, for #restore. Each theme is
    #   duplicated too, so a spec that reconfigures a registered theme in place
    #   cannot leak that change into later examples.
    def snapshot
      registry.transform_values(&:dup)
    end

    # @param state [Hash] a value from #snapshot
    def restore(state)
      registry.replace(state)
      invalidate_page_slugs!
    end

    def registry
      @registry ||= {}
    end
    private_class_method :registry
  end
end
