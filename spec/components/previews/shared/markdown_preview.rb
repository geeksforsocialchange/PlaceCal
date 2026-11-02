# frozen_string_literal: true

class Shared::MarkdownPreview < Lookbook::Preview
  # @label Document
  # @notes app/content/terms_of_use.md, as the terms of use page renders it.
  def default
    render Components::Directory::MarkdownContent.new(slug: "terms_of_use")
  end
end
