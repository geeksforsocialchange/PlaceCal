# frozen_string_literal: true

# The heading at the top of a directory sidebar card, shared by components and views.
# An h2: the cards are top-level sections, and an event page has no h2 above them.
module Components::SidebarHeading
  def sidebar_heading(text)
    render(Components::UI::Kicker.new(as: :h2, tone: :muted, spacing: :sm)) { text }
  end
end
