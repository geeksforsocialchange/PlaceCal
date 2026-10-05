# frozen_string_literal: true

# Fixture content page, registered with `theme.page` and served at
# /fixture-content. It is core's Views::ThemeContentPage with nothing added:
# a content root, a slug, a title and two markdown files, one of them behind a
# heading from the engine's own locale file.
class ExampleTheme::Views::Content < Views::ThemeContentPage
  content_root ExampleTheme::Engine.root.join("content")
  slug "fixture-content"
  title "example_theme.content.title"
  description "example_theme.content.description"

  markdown "intro.md"
  markdown "nested/detail.md", heading: "example_theme.content.detail"
end
