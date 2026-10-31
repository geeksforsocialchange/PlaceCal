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

  # Padding, not margin, so the space adds to the message's own margin instead of collapsing into it.
  def render_link
    div(class: 'pt-3') { UI::Link(href: @link_href, variant: :action) { @link_text } }
  end
end
