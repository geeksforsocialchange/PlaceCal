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
      theme = Current.site&.theme_definition
      overridable = overridable_key?(theme, key)

      # No override scope to consult (a lazy '.foo' key, or a request with no
      # theme), so let the `t` this module shadows do the whole job, including
      # ActionView's `_html` escaping and html_safe marking.
      return super if defined?(super) && !overridable

      options = escape_html_interpolations(key, options)
      value = overridable ? theme_scoped_translation(theme, key, **options) : I18n.t(key, **options)

      html_key?(key) && value.is_a?(String) ? value.html_safe : value # rubocop:disable Rails/OutputSafety
    end

    private

    # Try the theme's override first, then the key the caller asked for, then
    # whatever defaults the caller supplied.
    def theme_scoped_translation(theme, key, **options)
      scoped = "#{OVERRIDE_SCOPE}.#{theme.name}.#{key}"
      # The scoped key is absolute, so there is nothing the including class's
      # own `t` would add here; go straight to I18n.
      I18n.t(scoped, **options, default: [key.to_sym, *Array(options[:default])])
    rescue I18n::MissingTranslationData => e
      # Report the key the caller wrote, not the theme_overrides path they
      # have never heard of.
      raise I18n::MissingTranslationData.new(e.locale, key, e.options)
    end

    # Whether this key could carry a theme override: an absolute key (a lazy
    # '.foo' key only means anything to the including class's own `t`, which
    # knows the current scope) on a site whose theme is registered.
    def overridable_key?(theme, key)
      !theme.nil? && key.is_a?(String) && !key.start_with?('.')
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
