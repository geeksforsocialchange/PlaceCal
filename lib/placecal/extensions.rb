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
      registry[theme.name] = theme
      theme
    end

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
    end

    # @return [Hash] a copy of the registry state, for #restore
    def snapshot
      registry.dup
    end

    # @param state [Hash] a value from #snapshot
    def restore(state)
      registry.replace(state)
    end

    def registry
      @registry ||= {}
    end
    private_class_method :registry
  end
end
