# frozen_string_literal: true

# @display context directory
class UI::HeadingPreview < Lookbook::Preview
  # Serif section heading (`text-section`), an h2 by default. Spacing is set at the call site.
  # @label Section
  def section
    render(Components::UI::Heading.new) { "What's on this week" }
  end

  # Smaller serif heading (`text-subhead`) for cards and steps inside a section.
  # @label Subhead
  def subhead
    render(Components::UI::Heading.new(level: 3, size: :subhead)) { "Training for your team" }
  end
end
