# frozen_string_literal: true

require_relative 'extensions'

module PlaceCal
  # The engine infrastructure every extension used to copy (#3368 WP 5.2).
  #
  # An extension's engine is an ordinary Rails engine that includes this
  # module and declares two things: the settings it needs the host to support,
  # and the theme it registers.
  #
  #   module Transdimension
  #     class Engine < ::Rails::Engine
  #       include PlaceCal::Extension
  #
  #       required_settings %i[stylesheet homepage_view map_style]
  #
  #       theme :transdimension do |theme|
  #         theme.stylesheet    'transdimension/theme'
  #         theme.homepage_view 'Transdimension::Views::Home'
  #         theme.map_style     'transdimension'
  #       end
  #     end
  #   end
  #
  # That gives the engine, without another line in the extension:
  #
  # * Zeitwerk directories for app/views/<name> and app/components/<name>,
  #   pushed under the extension's own Views and Components namespaces, and
  #   only for the directories it actually ships.
  # * The host guard (#verify_host!) and the theme guard (#verify_theme!),
  #   both run before registration, so an installation missing the registry or
  #   a setting fails by name rather than with a NoMethodError from inside an
  #   initializer.
  # * Registration through PlaceCal::Extensions.register_theme.
  #
  # It is a module rather than a Rails::Engine subclass on purpose. Rails
  # collects railties with `Rails::Engine.subclasses`, which is Ruby's
  # `Class#subclasses` and returns direct subclasses only, so an engine that
  # inherited from a base class shipped by core would never be found and none
  # of its initializers would run.
  #
  # Core requires this file from config/application.rb before Bundler requires
  # the extension gems, because an engine's class body includes it at require
  # time. An older core therefore has no PlaceCal::Extension at all, which is
  # what the two-line guard in an extension's lib/<name>.rb reports; see
  # doc/extensions.md.
  module Extension
    # Raised when the host PlaceCal is too old to serve this theme.
    class UnsupportedHost < StandardError; end

    # Phlex directories an extension may ship, and the constant under the
    # extension's own namespace that each is autoloaded into.
    PHLEX_DIRS = { 'app/views' => :Views, 'app/components' => :Components }.freeze

    def self.included(base)
      raise ArgumentError, "#{base} must be a Rails::Engine to include PlaceCal::Extension" unless base.is_a?(Class) && base < ::Rails::Engine

      base.extend(ClassMethods)
      base.define_extension_initializers
    end

    # The extension DSL and the guards, on the engine class.
    module ClassMethods
      # The module the engine lives in: Transdimension for
      # Transdimension::Engine. Everything else is derived from it.
      #
      # @return [Module]
      def extension_namespace
        module_parent
      end

      # Snake-case name of the extension: the directory its views and
      # components live in, and the prefix of its initializer names.
      #
      # @return [String]
      def extension_name
        @extension_name ||= extension_namespace.name.demodulize.underscore
      end

      # Declare the theme this engine registers, and how to configure it.
      #
      #   theme :transdimension do |theme|
      #     theme.stylesheet 'transdimension/theme'
      #   end
      #
      # @param name [Symbol, String]
      # @yield [PlaceCal::Theme] configured at boot, and by a theme's own
      #   contract spec against a throwaway Theme
      # @return [Symbol] the theme name
      def theme(name, &block)
        @theme_name = name.to_sym
        @theme_block = block
        @theme_name
      end

      # @return [Symbol, nil] the declared theme name
      def theme_name
        @theme_name
      end

      # Every theme DSL setting this engine uses, so a host that is missing one
      # is named rather than discovered. Called with settings it declares them;
      # called with none it reads them back.
      #
      #   required_settings %i[stylesheet homepage_view map_style]
      #
      # @param settings [Array<Symbol>]
      # @return [Array<Symbol>]
      def required_settings(*settings)
        return @required_settings ||= [] if settings.empty?

        @required_settings = settings.flatten.map(&:to_sym).freeze
      end

      # @return [Module, nil] the host registry, or nil on a core too old to
      #   have one
      def host_registry
        defined?(::PlaceCal::Extensions) ? ::PlaceCal::Extensions : nil
      end

      # An older core has no extension registry, or a registry whose Theme is
      # missing settings added later. Either way the failure would otherwise be
      # a bare NoMethodError raised from inside an initializer, which says
      # nothing about what the installation needs. Name the missing capability
      # instead.
      #
      # @raise [UnsupportedHost]
      def verify_host!(registry = host_registry)
        return if registry.respond_to?(:register_theme)

        raise UnsupportedHost,
              'PlaceCal::Extensions.register_theme is not available: this theme needs a PlaceCal ' \
              'with the extension theme registry (see "Minimum core" in the engine README).'
      end

      # @param theme [PlaceCal::Theme]
      # @raise [UnsupportedHost]
      def verify_theme!(theme)
        missing = required_settings.reject { |setting| theme.respond_to?(setting) }
        return if missing.empty?

        raise UnsupportedHost,
              "PlaceCal::Theme does not support #{missing.join(', ')}: this theme needs a newer " \
              'PlaceCal (see "Minimum core" in the engine README).'
      end

      # Everything this engine says to a PlaceCal::Theme, in one callable place
      # so an extension's own contract spec can run it against a throwaway real
      # Theme. A changed signature in core then fails there rather than from
      # inside an initializer on the next boot.
      #
      # @param theme [PlaceCal::Theme]
      # @return [PlaceCal::Theme]
      def configure_theme(theme)
        verify_theme!(theme)
        @theme_block&.call(theme)
        theme
      end

      # @return [PlaceCal::Theme]
      def register_theme!
        raise ArgumentError, "#{name} includes PlaceCal::Extension but declares no theme" if theme_name.nil?

        verify_host!
        ::PlaceCal::Extensions.register_theme(theme_name) { |theme| configure_theme(theme) }
      end

      # Rails does not autoload app/views, and it autoloads app/components
      # under the top-level namespace, so the engine pushes its own
      # directories with explicit namespaces. Core does the same for Views and
      # Components in config/initializers/phlex.rb.
      #
      # @param engine_root [Pathname]
      # @return [Array<Array(Pathname, Module)>] only the directories the
      #   extension ships, so an extension with no components of its own
      #   ships no app/components at all
      def phlex_dirs(engine_root)
        PHLEX_DIRS.filter_map do |dir, const|
          path = Pathname(engine_root).join(dir, extension_name)
          next unless path.directory?
          next unless extension_namespace.const_defined?(const, false)

          [path, extension_namespace.const_get(const, false)]
        end
      end

      # @param engine_root [Pathname]
      def push_phlex_dirs!(engine_root)
        phlex_dirs(engine_root).each do |path, namespace|
          Rails.autoloaders.main.push_dir(path, namespace: namespace)
        end
      end

      # Called once, when the engine class includes PlaceCal::Extension. The
      # blocks read the class's declarations at boot, so `theme` and
      # `required_settings` may come after the include.
      def define_extension_initializers
        initializer "#{extension_name}.phlex_namespaces", before: :set_autoload_paths do
          self.class.push_phlex_dirs!(root)
        end

        # Theme registration (#3368 D1). Runs before core's
        # config/initializers, which is why core requires the registry from
        # config/application.rb.
        initializer "#{extension_name}.register_theme" do
          self.class.register_theme!
        end
      end
    end
  end
end
