# frozen_string_literal: true

# Renders a Site's static content page (#3368, D5). Uses the same wrapper
# classes as Views::Directory::MarkdownPage so themes only have to style one
# long-form content treatment.
class Views::Sites::Pages::Show < Views::Base
  prop :page, Page, reader: :private

  def view_template
    content_for(:title) { page.title }
    content_for(:description) { page.summary }

    div(class: 'container-public py-8') do
      h1(class: 'h1') { page.title }

      div(class: 'markdown-content max-w-(--width-prose-lg) text-base leading-relaxed') do
        raw safe(page.body_html.to_s)
      end
    end
  end
end
