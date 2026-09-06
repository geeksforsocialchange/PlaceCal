# frozen_string_literal: true

# Fixture homepage view. Inherits the core Views::Base so it gets the Rails
# helpers, t(), and the core Components kit.
class ExampleTheme::Views::Home < Views::Base
  prop :site, _Nilable(Site), reader: :private

  def view_template
    content_for(:title) { t("example_theme.home.title") }
    section(class: "example-theme-home") do
      h1 { t("example_theme.home.heading") }
      p { site ? site.name : t("example_theme.home.no_site") }
    end
  end
end
