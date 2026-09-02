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
      @event_filter_style = :date_picker
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

    # @param value [Symbol, nil] one of EVENT_FILTER_STYLES
    def event_filter_style(value = nil)
      return @event_filter_style if value.nil?

      value = value.to_sym
      raise ArgumentError, "unknown event_filter_style #{value.inspect}, expected one of #{EVENT_FILTER_STYLES.inspect}" unless EVENT_FILTER_STYLES.include?(value)

      @event_filter_style = value
    end

    # ---- Resolution

    # @param site [Site]
    # @return [String, nil] stylesheet logical path for this site, or nil
    def stylesheet_for(site)
      resolve(@stylesheet, site)
    end

    # @param site [Site]
    # @return [String, nil] map style name for this site, or nil
    def map_style_for(site)
      resolve(@map_style, site)
    end

    # @return [Class, nil] the homepage Phlex view class, or nil when the
    #   theme uses core's default homepage
    def homepage_view_class
      @homepage_view&.constantize
    end

    # @return [Class, nil] the head Phlex component class, or nil
    def head_class
      @head&.constantize
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
  end
end
