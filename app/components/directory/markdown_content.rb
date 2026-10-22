# frozen_string_literal: true

# A document from app/content/*.md, in the site's prose styles.
class Components::Directory::MarkdownContent < Components::Directory::Base
  CONTENT_DIR = Rails.root.join('app/content')

  prop :slug, String

  def view_template
    div(class: 'markdown-content max-w-(--width-prose-lg) text-base leading-relaxed') do
      raw safe(rendered_html)
    end
  end

  private

  def rendered_html
    markdown = CONTENT_DIR.join("#{@slug}.md").read
    html = Kramdown::Document.new(markdown).to_html
    Rails::HTML5::SafeListSanitizer.new.sanitize(html)
  end
end
