# frozen_string_literal: true

# The heading at the top of a directory sidebar card, shared by components and views.
module Components::SidebarHeading
  def sidebar_heading(text)
    render(Components::UI::Kicker.new(as: :h3, tone: :muted, spacing: :sm)) { text }
  end
end
