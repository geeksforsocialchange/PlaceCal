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
  # Each setting is optional.
  class Theme
    EVENT_FILTER_STYLES = %i[date_picker day_strip].freeze

    # Slug format for a theme page (`theme.page`). Same shape as the URLs core
    # already serves, so a theme page cannot introduce a path segment the
    # router would not match.
    PAGE_SLUG_FORMAT = /\A[a-z0-9-]+\z/

    # Returned by #pages for a theme that registers none, including NONE.
    NO_PAGES = {}.freeze

    # Icon slots a theme may fill. Each value is an asset logical path
    # (e.g. "transdimension/favicons/favicon-32x32.png"). A theme that sets
    # any of these replaces core's favicon and touch icon entirely.
    ICON_PATH_KEYS = %i[favicon_32 favicon_16 apple_touch_icon mask_icon icon_192 icon_512].freeze

    # `mask_icon_color` sits with the icons rather than on its own because it
    # is only ever read beside `mask_icon` and means nothing without it.
    ICON_KEYS = (ICON_PATH_KEYS + %i[mask_icon_color]).freeze

    # A colour, not an asset path: hex, rgb()/rgba(), or a CSS colour keyword.
    COLOUR_FORMAT = %r{\A(#[0-9a-f]{3,8}|[a-z]+|rgba?\([\d\s.,%/]+\))\z}i

    # Declared settings. Each `setting` call defines one method that stores a
    # cast value when called with one and reads the current value when called
    # with none, and registers the default an instance starts with. Settings
    # that validate, take structured arguments or accept a block keep their own
    # bodies below.
    @settings = {}

    class << self
      # @return [Hash{Symbol => Object}] declared setting names and their defaults
      attr_reader :settings

      # @param name [Symbol] setting and method name
      # @param cast [Symbol] :to_s or :boolean
      # @param default [Object] the value an instance starts with
      # @param predicate [Boolean] also define a `name?` reader
      def setting(name, cast: :to_s, default: nil, predicate: false)
        settings[name] = default
        ivar = :"@#{name}"

        define_method(name) do |value = nil|
          return instance_variable_get(ivar) if value.nil?

          instance_variable_set(ivar, cast == :boolean ? value != false : value.to_s)
        end

        define_method(:"#{name}?") { instance_variable_get(ivar) } if predicate
      end
    end

    attr_reader :name

    # @param name [Symbol, String]
    # @param core [Boolean] true for the built-in themes shipped by core; they
    #   sort first in the registry so admin selects list them before extensions.
    def initialize(name, core: false)
      @name = name.to_s
      @core = core
      self.class.settings.each { |setting, default| instance_variable_set(:"@#{setting}", default) }
      # Defaults for the settings whose bodies are written out below.
      @icons = {}
      @font_stylesheet = nil
      @og_image = nil
      @nav_cta = nil
      @pages = {}
      @event_filter_style = :date_picker
      @warned = Set.new
    end

    # Registry snapshots (PlaceCal::Extensions.snapshot) dup every theme so a
    # spec that reconfigures one in place cannot leak the change into later
    # examples. A shallow dup would share the mutable containers, so dup them
    # too.
    def initialize_copy(other)
      super
      @pages = other.pages.dup
      @icons = other.icons.dup
      @warned = Set.new
    end

    def core?
      @core
    end

    # ---- DSL: each method sets when given a value, reads otherwise.

    # @param value [String, nil] asset logical path without extension, e.g. "themes/pink"
    setting :stylesheet

    # @param value [String, nil] Phlex view class name, resolved lazily so
    #   registration can happen before autoloading is set up.
    setting :homepage_view

    # @param value [String, nil] name of public/map-styles/<name>.json, or of
    #   an extension asset at map-styles/<name>.json
    setting :map_style

    # @param value [String, nil] Phlex component class name rendered in <head>
    setting :head

    # A webfont stylesheet the theme's sites load, with the origins worth
    # preconnecting to. Rendered in <head> as those preconnects, a preload and
    # the stylesheet link, which is the whole of what a theme's head component
    # used to exist for.
    #
    #   theme.font_stylesheet 'https://use.typekit.net/qwi3qrw.css',
    #                         preconnect: %w[https://use.typekit.net https://p.typekit.net]
    #
    # `theme.head` stays the escape hatch for anything genuinely bespoke.
    #
    # @param url [String, nil]
    # @param preconnect [Array<String>] origins to preconnect to, normally the
    #   font host and wherever it serves the font files from
    # @return [Hash, nil] { url:, preconnect: } when called with no arguments
    def font_stylesheet(url = nil, preconnect: [])
      return @font_stylesheet if url.nil?

      @font_stylesheet = { url: url.to_s, preconnect: Array(preconnect).map(&:to_s) }
    end

    # @param value [String, nil] hex colour code for web manifest, e.g. "#f19089"
    setting :theme_color

    # The theme's own favicons, touch icon, Safari mask icon and manifest
    # icons. Given as asset logical paths, resolved with `image_url` at render
    # time, so an engine ships them under app/assets/images/<extension>/.
    # `mask_icon_color` is the odd one out: a colour, used as the `color`
    # attribute of the mask icon's link.
    #
    #   theme.icons favicon_32: "transdimension/favicons/favicon-32x32.png",
    #               favicon_16: "transdimension/favicons/favicon-16x16.png",
    #               apple_touch_icon: "transdimension/favicons/apple-touch-icon.png",
    #               mask_icon: "transdimension/favicons/safari-pinned-tab.svg",
    #               mask_icon_color: "#FF7AA7",
    #               icon_192: "transdimension/favicons/android-chrome-192x192.png",
    #               icon_512: "transdimension/favicons/android-chrome-512x512.png"
    #
    # When any icon is set the layout links the theme's icons in place of
    # core's favicon.png and apple-touch-icon.png. Defaults to {}.
    #
    # @param paths [Hash] any subset of ICON_KEYS
    # @raise [ArgumentError] on an unknown key, or a mask_icon_color that is
    #   not a colour (an asset path there is a silently wrong mask icon)
    # @return [Hash] the icon paths when called with no arguments
    def icons(**paths)
      return @icons if paths.empty?

      unknown = paths.keys - ICON_KEYS
      raise ArgumentError, "unknown icon key(s) #{unknown.inspect}, expected any of #{ICON_KEYS.inspect}" if unknown.any?

      icons = paths.transform_values { |path| path&.to_s.presence }.compact
      validate_mask_icon_color!(icons[:mask_icon_color])
      @icons = icons
    end

    # Splash background colour for the web manifest. Distinct from
    # `theme_color`, which colours the browser chrome.
    #
    # @param value [String, nil] hex colour code, e.g. "#040f39"
    setting :background_color

    # A static Open Graph share image for the theme's sites, replacing core's
    # generated share card.
    #
    #   theme.og_image "transdimension/og.png", width: 1200, height: 675
    #
    # @param path [String, nil] asset logical path
    # @param width [Integer, nil]
    # @param height [Integer, nil]
    # @return [Hash, nil] { path:, width:, height: } when called with no arguments
    def og_image(path = nil, width: nil, height: nil)
      return @og_image if path.nil?

      @og_image = { path: path.to_s, width: width, height: height }
    end

    # @param value [String, nil] Phlex component class name rendered in place
    #   of core's site footer; constructed with `new(site:, navigation:)`
    setting :footer

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

    # A static content page the theme serves at `/<slug>` on its sites.
    # Core keeps no page content of its own: the copy lives in the theme's
    # own Phlex view, which is constructed with `new(site:)`.
    #
    #   theme.page 'about', 'MyExt::Views::About', nav_label_key: 'my_ext.nav.about'
    #
    # Repeatable; pages keep their registration order, which is the order they
    # appear in the site nav. A page with no `nav_label_key` is served but not
    # linked from the nav.
    #
    # @param slug [String, Symbol] first path segment, lowercase letters, numbers and hyphens
    # @param view_class_name [String] Phlex view class name, resolved lazily
    # @param nav_label_key [String, nil] locale key for the nav label
    # @raise [ArgumentError] on a malformed slug
    def page(slug, view_class_name, nav_label_key: nil)
      slug = slug.to_s
      raise ArgumentError, "invalid page slug #{slug.inspect}, expected lowercase letters, numbers and hyphens" unless slug.match?(PAGE_SLUG_FORMAT)

      @pages[slug] = { view: view_class_name.to_s, nav_label_key: nav_label_key&.to_s }
      # The /:slug route constraint is built from every theme's slugs, and a
      # theme may gain a page after it was registered.
      Extensions.invalidate_page_slugs!
      self
    end

    # A slug that collides with a core route is harmless: the `/:slug`
    # catch-all is appended after every other route, so the core route wins and
    # the theme's page is never served.
    #
    # @return [Hash{String => Hash}] frozen, in registration order,
    #   `slug => { view:, nav_label_key: }`. Empty for a theme with no pages.
    def pages
      @pages.empty? ? NO_PAGES : @pages.dup.freeze
    end

    # @param slug [String]
    # @return [Class, nil] the page's Phlex view class, or nil when the theme
    #   has no such page or the class no longer resolves
    def page_view_class(slug)
      entry = pages[slug.to_s]
      return nil if entry.nil?

      constant_for(entry[:view], "page #{slug}")
    end

    # Whether the derived site nav (SiteNavigation) includes the Join link
    # when the site takes enquiries. A theme whose footer carries the link
    # instead sets this to false. Defaults to true.
    #
    # @param value [Boolean, nil]
    setting :nav_join, cast: :boolean, default: true, predicate: true

    # Whether the mobile menu toggle shows a "Menu" text label beside the icon.
    # The nationwide directory always shows it; sites show it only when their
    # theme opts in. Defaults to false.
    #
    # @param value [Boolean, nil]
    setting :menu_label, cast: :boolean, default: false, predicate: true

    # @param value [Symbol, nil] one of EVENT_FILTER_STYLES
    def event_filter_style(value = nil)
      return @event_filter_style if value.nil?

      value = value.to_sym
      raise ArgumentError, "unknown event_filter_style #{value.inspect}, expected one of #{EVENT_FILTER_STYLES.inspect}" unless EVENT_FILTER_STYLES.include?(value)

      @event_filter_style = value
    end

    # Null theme for a site whose theme is blank or unregistered, and for the
    # nationwide directory, which has no site at all. It answers every setting
    # with its default, so callers read theme settings without a nil check.
    NONE = new(:none).freeze

    # The one site-keyed way to a theme. Within a request prefer Current.theme,
    # which is this call made once by ApplicationController.
    #
    # @param site [Site, nil]
    # @return [PlaceCal::Theme] the site's theme, or NONE
    def self.for(site)
      (site && Extensions.find_theme(site.theme)) || NONE
    end

    # The one answer to "will the asset helpers find this?". `resolve` is what
    # stylesheet_link_tag and image_url call, so asking it is the only check
    # that cannot drift from what they do.
    #
    # @param logical_path [String] asset path including its extension
    # @return [Boolean]
    def self.asset_resolves?(logical_path)
      Rails.application.assets&.resolver&.resolve(logical_path).present?
    end

    # ---- Resolution

    # A theme's stylesheet is only linked when the asset pipeline can resolve
    # it. A renamed or unbuilt engine CSS file would otherwise raise
    # Propshaft::MissingAssetError on every page of the site (#3368).
    #
    # @return [String, nil] stylesheet logical path, or nil
    def stylesheet_path
      path = @stylesheet.presence
      return nil if path.nil?
      return path if asset_resolves?("#{path}.css")

      warn_once(:stylesheet, "stylesheet #{path}.css does not resolve in the asset pipeline; rendering without it")
      nil
    end

    # The theme's icons, minus any whose asset the pipeline cannot resolve. A
    # renamed or dropped engine image would otherwise raise
    # Propshaft::MissingAssetError from `image_url` on every page of every site
    # on the theme, which is the failure `stylesheet_path` already guards
    # against (#3368). Callers rendering icons read this, not #icons.
    #
    # @return [Hash] icon paths that resolve, plus mask_icon_color when its
    #   mask icon survived. Empty when none resolve, so core's icons render.
    def icons_for_render
      return @icons if @icons.empty?

      resolved = @icons.select do |key, path|
        next false unless ICON_PATH_KEYS.include?(key)
        next true if asset_resolves?(path)

        warn_once(:"icon_#{key}", "icon #{key} #{path} does not resolve in the asset pipeline; omitting it")
        false
      end
      return {} if resolved.empty?

      resolved[:mask_icon_color] = @icons[:mask_icon_color] if resolved[:mask_icon] && @icons[:mask_icon_color]
      resolved
    end

    # @return [Hash, nil] the share image, or nil when its asset does not
    #   resolve, in which case core's generated share card renders instead.
    def og_image_for_render
      return nil if @og_image.nil?
      return @og_image if asset_resolves?(@og_image[:path])

      warn_once(:og_image, "og_image #{@og_image[:path]} does not resolve in the asset pipeline; falling back to core's share card")
      nil
    end

    # @return [String, nil] map style name, or nil
    def map_style_name
      @map_style.presence
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

    def validate_mask_icon_color!(value)
      return if value.nil? || value.match?(COLOUR_FORMAT)

      raise ArgumentError, "invalid mask_icon_color #{value.inspect}, expected a colour such as \"#FF7AA7\""
    end

    def asset_resolves?(logical_path)
      self.class.asset_resolves?(logical_path)
    end

    # A theme names its classes as strings so registration can happen before
    # autoloading is ready. A renamed or removed class must not take the site
    # down: log it and let core's default render instead (#3368).
    #
    # @param class_name [String, nil]
    # @param setting [String] which DSL setting is being resolved, for the log
    # @return [Class, nil]
    def constant_for(class_name, setting)
      return nil if class_name.nil?

      class_name.constantize
    rescue NameError
      warn_once(:"class_#{setting}", "#{setting} class #{class_name} could not be resolved; falling back to core")
      nil
    end

    # A stale path or class name is a per-theme configuration fault, not a
    # per-request one: logging it on every render of every page would flood the
    # log stream. Say it once per setting, per theme, per boot.
    #
    # @param setting [Symbol] which setting is at fault
    # @param message [String]
    def warn_once(setting, message)
      return unless @warned.add?(setting)

      Rails.logger.warn("PlaceCal theme #{name}: #{message}")
    end
  end
end
