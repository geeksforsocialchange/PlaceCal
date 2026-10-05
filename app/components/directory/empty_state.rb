# frozen_string_literal: true

# Centered "nothing here" message shown when a directory listing or filter
# returns no results, with an optional reset/clear link.
class Components::Directory::EmptyState < Components::Directory::Base
  prop :message, String
  prop :link_text, _Nilable(String), default: nil
  prop :link_href, _Nilable(String), default: nil

  def view_template
    div(class: 'py-10 text-center') do
      p(class: 'text-tertiary text-lg') { @message }
      render_link if @link_text && @link_href
    end
  end

  private

  def render_link
    a(href: @link_href,
      class: 'inline-flex items-center gap-2 mt-3 text-foreground font-bold no-underline hover:underline') do
      plain @link_text
    end
  end
end
