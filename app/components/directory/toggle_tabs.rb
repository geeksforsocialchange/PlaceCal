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
    nav(class: 'py-2', aria_label: @aria_label) do
      UI::Cluster(gap: :xs, align: :stretch) do
        @items.each do |item|
          UI::Pill(selected: item[:active], href: item[:href]) { plain item[:label] }
        end
      end
    end
  end
end
