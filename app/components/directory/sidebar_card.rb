# frozen_string_literal: true

# A directory sidebar card with a dark header (optional allcaps eyebrow +
# serif title) over a light body. The shared idiom behind the partner
# sidebar's "Part of" card and the event page's "Organised by" card, so
# entity-titled cards look identical across the directory.
class Components::Directory::SidebarCard < Components::Directory::Base
  prop :title, String
  prop :eyebrow, _Nilable(String), default: nil
  prop :title_href, _Nilable(String), default: nil

  def view_template(&block)
    div(class: 'rounded-card overflow-hidden') do
      div(class: 'bg-foreground px-4 py-3', style: 'color: var(--color-background)') do
        div(class: 'allcaps-label mb-0.5 opacity-80') { @eyebrow } if @eyebrow
        render_title
      end
      div(class: 'bg-home-background-3 px-4 py-3', &block) if block
    end
  end

  private

  def render_title
    if @title_href
      a(href: @title_href, class: 'font-serif text-lg no-underline hover:underline', style: 'color: inherit') { @title }
    else
      div(class: 'font-serif text-lg') { @title }
    end
  end
end
