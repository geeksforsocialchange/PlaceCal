# frozen_string_literal: true

# @display context directory
class UI::HeadingPreview < Lookbook::Preview
  # Serif section heading (`text-section`), an h2 by default, with the base heading margins.
  # @label Section
  def section
    render(Components::UI::Heading.new) { "What's on this week" }
  end

  # Smaller serif heading (`text-subhead`) for cards and steps inside a section.
  # @label Subhead
  def subhead
    render(Components::UI::Heading.new(level: 3, size: :subhead)) { "Training for your team" }
  end

  # `spacing:` drops the top margin and sets the space below from the layout scale (`:none`, `:xs`, `:sm`, `:md`, `:lg` or `:xl`).
  # @label Spacing
  def spacing
    safe_join([render(Components::UI::Heading.new(spacing: :md)) { "Frequently asked questions" },
               tag.p(class: "my-0") { "The paragraph starts one :md step under the heading." }])
  end
end
