# frozen_string_literal: true

# Rendered markdown in the site's prose styles.
class Components::Shared::Markdown < Components::Base
  theme_scope :markdown,
              parts: { root: 'The column of rendered markdown: paragraphs, headings, lists and rules, as the document has them.' },
              tokens: %i[--text-base --text-2xl --leading-relaxed --font-weight-bold --color-rules --color-foreground --color-primary]

  def view_template(&)
    UI::Text(as: :div, measure: :prose_lg, **part(:root, class: 'markdown-content'), &)
  end
end
