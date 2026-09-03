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

    def t(key, **)
      theme = Current.site&.theme_definition
      return I18n.t(key, **) unless theme && key.is_a?(String) && !key.start_with?('.')

      I18n.t("#{OVERRIDE_SCOPE}.#{theme.name}.#{key}", **, default: key.to_sym)
    end
  end
end
