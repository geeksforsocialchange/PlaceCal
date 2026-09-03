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

    # Slug format for a theme page (`theme.page`). Same shape as the URLs core
    # already serves, so a theme page cannot introduce a path segment the
    # router would not match.
    PAGE_SLUG_FORMAT = /\A[a-z0-9-]+\z/

    # Path prefixes served outside the Rails router (Propshaft and friends), so
    # they never appear in `Rails.application.routes` but would still shadow a
    # theme page.
    NON_ROUTED_RESERVED_SLUGS = %w[assets packs manifest].freeze

    # `privacy` is deliberately allowed even though core routes `/privacy`.
    # PagesController#privacy prefers the theme's own privacy page and only
    # falls back to the directory markdown, so a partnership can supply its own
    # privacy copy at the conventional URL (#3368 D14). No other core route is
    # overridable this way.
    OVERRIDABLE_ROUTE_SLUGS = %w[privacy].freeze

    # Returned by #pages for a theme that registers none, including NONE.
    NO_PAGES = {}.freeze

    # Icon slots a theme may fill. Each value is an asset logical path
    # (e.g. "transdimension/favicons/favicon-32x32.png"). A theme that sets
    # any of these replaces core's favicon and touch icon entirely.
    ICON_KEYS = %i[favicon_32 favicon_16 apple_touch_icon mask_icon icon_192 icon_512].freeze

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
      # Slugs a theme page may not claim, because a core route already owns
      # that first path segment. Derived from the router so new core routes are
      # covered automatically.
      #
      # Computed lazily and memoised rather than at registration time: an
      # engine registers its theme from an initializer, long before the route
      # set is drawn, so the check runs the first time a theme's pages are
      # read (the first request that renders a nav, a page or a sitemap).
      #
      # @return [Array<String>]
      def reserved_page_slugs
        @reserved_page_slugs ||= begin
          routed = Rails.application.routes.routes.filter_map do |route|
            next if route.constraints[:subdomain] == Site::ADMIN_SUBDOMAIN

            segment = route.path.spec.to_s.split('/')[1].to_s.sub(/\(.*/, '')
            next if segment.blank? || segment.start_with?('*', ':')

            segment.downcase
          end

          (routed + NON_ROUTED_RESERVED_SLUGS - OVERRIDABLE_ROUTE_SLUGS).uniq.sort.freeze
        end
      end

      # Clears the memoised reserved slug list (tests that redraw routes).
      def reset_reserved_page_slugs!
        @reserved_page_slugs = nil
      end

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
      @stylesheet = nil
      @map_style = nil
      @icons = {}
      @og_image = nil
      @nav_cta = nil
      @pages = {}
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
    setting :homepage_view

    # @param value [String, nil] name of public/map-styles/<name>.json
    def map_style(value = nil, &block)
      return @map_style if value.nil? && block.nil?

      @map_style = block || value.to_s
    end

    # @param value [String, nil] Phlex component class name rendered in <head>
    setting :head

    # @param value [String, nil] hex colour code for web manifest, e.g. "#f19089"
    setting :theme_color

    # The theme's own favicons, touch icon, Safari mask icon and manifest
    # icons. Given as asset logical paths, resolved with `image_url` at render
    # time, so an engine ships them under app/assets/images/<extension>/.
    #
    #   theme.icons favicon_32: "transdimension/favicons/favicon-32x32.png",
    #               favicon_16: "transdimension/favicons/favicon-16x16.png",
    #               apple_touch_icon: "transdimension/favicons/apple-touch-icon.png",
    #               mask_icon: "transdimension/favicons/safari-pinned-tab.svg",
    #               icon_192: "transdimension/favicons/android-chrome-192x192.png",
    #               icon_512: "transdimension/favicons/android-chrome-512x512.png"
    #
    # When any icon is set the layout links the theme's icons in place of
    # core's favicon.png and apple-touch-icon.png. Defaults to {}.
    #
    # @param paths [Hash] any subset of ICON_KEYS
    # @raise [ArgumentError] on an unknown key
    # @return [Hash] the icon paths when called with no arguments
    def icons(**paths)
      return @icons if paths.empty?

      unknown = paths.keys - ICON_KEYS
      raise ArgumentError, "unknown icon key(s) #{unknown.inspect}, expected any of #{ICON_KEYS.inspect}" if unknown.any?

      @icons = paths.transform_values { |path| path&.to_s.presence }.compact
    end

    # Colour for the Safari pinned-tab mask icon, used as the `color`
    # attribute of `<link rel="mask-icon">`.
    #
    # @param value [String, nil] hex colour code, e.g. "#FF7AA7"
    setting :mask_icon_color

    # Splash background colour for the web manifest. Distinct from
    # `theme_color`, which colours the browser chrome.
    #
    # @param value [String, nil] hex colour code, e.g. "#040f39"
    setting :background_color

    # The manifest's background_color, falling back to the theme colour when
    # the theme sets only one of the two.
    #
    # @return [String, nil]
    def manifest_background_color
      @background_color || @theme_color
    end

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
      self
    end

    # @return [Hash{String => Hash}] frozen, in registration order,
    #   `slug => { view:, nav_label_key: }`. Empty for a theme with no pages.
    # @raise [ArgumentError] when a slug shadows a core route
    def pages
      return NO_PAGES if @pages.empty?

      reject_reserved_slugs!
      @pages.dup.freeze
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

    # @param site [Site, nil]
    # @return [PlaceCal::Theme] the site's theme, or NONE
    def self.for(site)
      site&.theme_settings || NONE
    end

    # ---- Resolution

    # A theme's stylesheet is only linked when the asset pipeline can resolve
    # it. A renamed or unbuilt engine CSS file would otherwise raise
    # Propshaft::MissingAssetError on every page of the site (#3368).
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

    # Runs on the first read of #pages, not at registration: see
    # .reserved_page_slugs for why.
    def reject_reserved_slugs!
      reserved = self.class.reserved_page_slugs & @pages.keys
      return if reserved.empty?

      raise ArgumentError, "theme #{name}: page slug(s) #{reserved.inspect} are reserved by core routes"
    end

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
    # down: log it and let core's default render instead (#3368).
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
