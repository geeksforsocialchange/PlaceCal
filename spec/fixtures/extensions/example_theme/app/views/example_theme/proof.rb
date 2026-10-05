# frozen_string_literal: true

# Fixture theme page view, registered with `theme.page` and served at /proof
# on the fixture engine's sites. Core holds no content for it.
class ExampleTheme::Views::Proof < Views::Base
  prop :site, _Nilable(Site), reader: :private

  def view_template
    content_for(:title) { t("example_theme.proof.title") }
    section(class: "example-theme-page example-theme-page--proof") do
      h1 { t("example_theme.proof.heading") }
      p { site ? site.name : t("example_theme.home.no_site") }
    end
  end
end
