# frozen_string_literal: true

module PlaceCal
  # A theme definition: what an extension (or core) registers for a Site
  # theme name. Pure value object with a small DSL; no Rails model, no
  # database. See doc/extensions.md and #3368 (D1).
  #
  #   PlaceCal::Extensions.register_theme(:transdimension) do |theme|
  #     theme.stylesheet    'transdimension/theme'
  #     theme.homepage_view 'Transdimension::Views::Home'
  #     theme.map_style     'transdimension'
  #     theme.head          'Transdimension::Components::Head'
  #     theme.event_filter_style :day_strip
  #   end
  #
  # Each setting is optional. `stylesheet` and `map_style` may also be given
  # a block that receives the Site, for lookups that depend on the record
  # (the legacy :custom theme resolves by site slug that way).
  class Theme
    EVENT_FILTER_STYLES = %i[date_picker day_strip].freeze

    attr_reader :name

    # @param name [Symbol, String]
    # @param core [Boolean] true for the built-in themes shipped by core; they
    #   sort first in the registry so admin selects list them before extensions.
    def initialize(name, core: false)
      @name = name.to_s
      @core = core
      @stylesheet = nil
      @homepage_view = nil
      @map_style = nil
      @head = nil
      @theme_color = nil
      @event_filter_style = :date_picker
      @nav_join = true
    end

    def core?
      @core
    end

    # ---- DSL: each method sets when given a value or block, reads otherwise.

    # @param value [String, nil] asset logical path without extension, e.g. "themes/pink"
    def stylesheet(value = nil, &block)
      return @stylesheet if value.nil? && block.nil?

      @stylesheet = block || value.to_s
    end

    # @param value [String, nil] Phlex view class name, resolved lazily so
    #   registration can happen before autoloading is set up.
    def homepage_view(value = nil)
      return @homepage_view if value.nil?

      @homepage_view = value.to_s
    end

    # @param value [String, nil] name of public/map-styles/<name>.json
    def map_style(value = nil, &block)
      return @map_style if value.nil? && block.nil?

      @map_style = block || value.to_s
    end

    # @param value [String, nil] Phlex component class name rendered in <head>
    def head(value = nil)
      return @head if value.nil?

      @head = value.to_s
    end

    # @param value [String, nil] hex colour code for web manifest, e.g. "#f19089"
    def theme_color(value = nil)
      return @theme_color if value.nil?

      @theme_color = value.to_s
    end

    # @param value [String, nil] Phlex component class name rendered in place
    #   of core's site footer; constructed with `new(site:, navigation:)`
    def footer(value = nil)
      return @footer if value.nil?

      @footer = value.to_s
    end

    # Optional call-to-action button at the end of the site nav (for example
    # a Donate link). Rendered as a link to `url` labelled by the locale key.
    #
    # @param label_key [String, nil] locale key for the label
    # @param url [String, nil]
    # @return [Hash, nil] { label_key:, url: }
    def nav_cta(label_key = nil, url = nil)
      return @nav_cta if label_key.nil?

      @nav_cta = { label_key: label_key.to_s, url: url.to_s }
    end

    # Whether the derived site nav (SiteNavigation) includes the Join link
    # when the site takes enquiries. A theme whose footer carries the link
    # instead sets this to false. Defaults to true.
    #
    # @param value [Boolean, nil]
    def nav_join(value = nil)
      return @nav_join if value.nil?

      @nav_join = value ? true : false
    end

    def nav_join?
      @nav_join
    end

    # @param value [Symbol, nil] one of EVENT_FILTER_STYLES
    def event_filter_style(value = nil)
      return @event_filter_style if value.nil?

      value = value.to_sym
      raise ArgumentError, "unknown event_filter_style #{value.inspect}, expected one of #{EVENT_FILTER_STYLES.inspect}" unless EVENT_FILTER_STYLES.include?(value)

      @event_filter_style = value
    end

    # ---- Resolution

    # A theme's stylesheet is only linked when the asset pipeline can resolve
    # it. A renamed or unbuilt engine CSS file would otherwise raise
    # Propshaft::MissingAssetError on every page of the site (#3368 WP 3.1).
    #
    # @param site [Site]
    # @return [String, nil] stylesheet logical path for this site, or nil
    def stylesheet_for(site)
      path = resolve(@stylesheet, site)
      return nil if path.nil?
      return path if asset_resolves?("#{path}.css")

      Rails.logger.error("PlaceCal theme #{name}: stylesheet #{path}.css does not resolve in the asset pipeline; rendering without it")
      nil
    end

    # @param site [Site]
    # @return [String, nil] map style name for this site, or nil
    def map_style_for(site)
      resolve(@map_style, site)
    end

    # @return [Class, nil] the homepage Phlex view class, or nil when the
    #   theme uses core's default homepage
    def homepage_view_class
      constant_for(@homepage_view, 'homepage_view')
    end

    # @return [Class, nil] the head Phlex component class, or nil
    def head_class
      constant_for(@head, 'head')
    end

    # @return [Class, nil] the footer Phlex component class, or nil
    def footer_class
      constant_for(@footer, 'footer')
    end

    # Human label for admin selects. Themes may translate `themes.<name>.label`.
    def label
      I18n.t("themes.#{name}.label", default: name.titleize)
    end

    def to_s
      name
    end

    private

    def resolve(setting, site)
      value = setting.respond_to?(:call) ? setting.call(site) : setting
      value&.to_s.presence
    end

    # @param logical_path [String] asset path including extension
    # @return [Boolean] whether Propshaft can serve the asset
    def asset_resolves?(logical_path)
      Rails.application.assets&.load_path&.find(logical_path).present?
    end

    # A theme names its classes as strings so registration can happen before
    # autoloading is ready. A renamed or removed class must not take the site
    # down: log it and let core's default render instead (#3368 WP 3.1).
    #
    # @param class_name [String, nil]
    # @param setting [String] which DSL setting is being resolved, for the log
    # @return [Class, nil]
    def constant_for(class_name, setting)
      return nil if class_name.nil?

      class_name.constantize
    rescue NameError
      Rails.logger.error("PlaceCal theme #{name}: #{setting} class #{class_name} could not be resolved; falling back to core")
      nil
    end
  end
end
