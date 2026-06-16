# frozen_string_literal: true

# A row of pill toggles (e.g. the events period filter, the partners sort
# order). The selected tab renders as a static pill; the rest are links.
#
# @param items [Array<Hash>] each { label:, href:, active: }
# @param aria_label [String] accessible label for the nav landmark
class Components::Directory::ToggleTabs < Components::Directory::Base
  prop :items, _Interface(:each)
  prop :aria_label, String

  def view_template
    nav(class: 'flex gap-1 flex-wrap py-2', aria_label: @aria_label) do
      @items.each do |item|
        if item[:active]
          span(class: active_class) { plain item[:label] }
        else
          a(href: item[:href], class: inactive_class) { plain item[:label] }
        end
      end
    end
  end

  private

  def active_class
    'inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-foreground text-background'
  end

  def inactive_class
    'inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-home-background-3 ' \
      'text-foreground no-underline hover:bg-primary transition-colors'
  end
end
