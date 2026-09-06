# frozen_string_literal: true

module PlaceCal
  # `t` for views, components and controllers that lets a theme override any
  # core string for the sites that use that theme, and only those sites
  # (#3368, D19). An extension ships the overrides in its own locale file
  # under `theme_overrides.<theme name>.<original key>`; nothing is changed
  # for sites on other themes, and no load-order tricks are needed.
  #
  #   en:
  #     theme_overrides:
  #       transdimension:
  #         region_filter:
  #           all: Everywhere
  module ThemeTranslation
    OVERRIDE_SCOPE = 'theme_overrides'

    # Interpolation keys I18n itself owns; every other option is caller data
    # and gets escaped for an `_html` key, as ActionView's `t` does.
    RESERVED_INTERPOLATIONS = %i[count default scope locale raise throw separator].freeze

    # This shadows ActionView's `t` (and the controller's) for the whole
    # application: the module is included into Components::Base, Views::Base,
    # Views::Layouts::Application and ApplicationController, which is the
    # ancestor of Admin::* too. That breadth is deliberate. The fidelity goal
    # is that any core string may be overridden by a theme without core
    # growing a conditional or the theme forking a view, and there is no way
    # to know in advance which of the several hundred strings a theme will
    # want. The cost is that every `t` call in the app passes through here, so
    # this method must behave exactly like the `t` it replaces whenever there
    # is no override to apply: when there is a `super`, the call is handed
    # straight to it rather than reimplemented.
    def t(key, **options)
      override = override_key(Current.theme, key, options)

      # No override to apply (no theme, a lazy '.foo' key, or simply a key
      # this theme does not rewrite), so let the `t` this module shadows do
      # the whole job, including ActionView's `_html` escaping, its html_safe
      # marking and its missing-translation reporting.
      return super if override.nil? && defined?(super)

      options = escape_html_interpolations(key, options)
      # `scope:` has already been folded into the override key; passing it on
      # would send I18n looking under the scope for the absolute key.
      value = override ? I18n.t(override, **options.except(:scope)) : I18n.t(key, **options)

      html_key?(key) && value.is_a?(String) ? value.html_safe : value # rubocop:disable Rails/OutputSafety
    end

    private

    # The theme_overrides key that exists for this call, or nil when there is
    # nothing to override. Looking first rather than relying on I18n's default
    # chain matters: a miss down that chain returns a "Translation missing"
    # string naming the internal theme_overrides path, which is not a phrase
    # the caller has ever heard of and would be rendered to the reader.
    #
    # A lazy ('.foo') key is left alone: it only means anything to the
    # including class's own `t`, which knows the current scope. The null theme
    # has no overrides, so short-circuit rather than send every directory
    # lookup through a `theme_overrides.none.<key>` miss.
    #
    # @param theme [PlaceCal::Theme]
    # @param key [String, Symbol]
    # @param options [Hash] the caller's `t` options; `scope:` and `locale:`
    #   are honoured, since both change which key the caller means
    # @return [String, nil]
    def override_key(theme, key, options)
      return nil if theme.equal?(PlaceCal::Theme::NONE)
      return nil unless key.is_a?(String) || key.is_a?(Symbol)

      key = key.to_s
      return nil if key.start_with?('.')

      scoped = "#{OVERRIDE_SCOPE}.#{theme.name}.#{[*options[:scope], key].join('.')}"
      scoped if I18n.exists?(scoped, options[:locale] || I18n.locale)
    end

    # Only reached when there is no `super` to do it (Phlex components), or for
    # a key the theme may override, which I18n resolves directly.
    def escape_html_interpolations(key, options)
      return options unless html_key?(key)

      options.to_h do |name, value|
        next [name, value] if RESERVED_INTERPOLATIONS.include?(name) || value.is_a?(ActiveSupport::SafeBuffer)

        [name, ERB::Util.html_escape(value)]
      end
    end

    def html_key?(key)
      key.to_s.end_with?('_html')
    end
  end
end
