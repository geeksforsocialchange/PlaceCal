# frozen_string_literal: true

# Renders a static markdown document (e.g. legal pages) from app/content/*.md
# through the directory page chrome. Keeps long-form legal copy reviewable in
# diffs and editable without touching Ruby — see issue #3248.
class Views::Directory::MarkdownPage < Views::Base
  theme_scope :markdown_page, parts: { root: 'The column under the hero holding the document.' }

  prop :slug, String
  prop :title, String
  prop :breadcrumb_label, String
  prop :document_title, String
  prop :description, String

  def view_template
    content_for(:title) { @document_title }
    content_for(:description) { @description }

    Directory::PageHero(
      title: @title,
      breadcrumb_label: @breadcrumb_label
    )

    div(**part(:root, class: 'container-public py-8')) do
      Directory::MarkdownContent(slug: @slug)
    end
  end
end
