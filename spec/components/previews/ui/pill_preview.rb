# frozen_string_literal: true

# @display context directory
class UI::PillPreview < Lookbook::Preview
  # @label Tabs
  # @notes One option is selected and renders as text; the others are links. Used for the events period and partners sort order.
  def tabs
    render(Row.new do |r|
      r.render(Components::UI::Pill.new(selected: true, href: "#")) { "This week" }
      r.render(Components::UI::Pill.new(href: "#")) { "This month" }
      r.render(Components::UI::Pill.new(href: "#")) { "All upcoming" }
    end)
  end

  # @label Small
  # @notes `:tag` for category links, `:count` for counts, `:muted` for categories on cream cards.
  def small
    render(Row.new do |r|
      r.render(Components::UI::Pill.new(variant: :tag, href: "#")) { "Arts" }
      r.render(Components::UI::Pill.new(variant: :count)) { "3 events" }
      r.render(Components::UI::Pill.new(variant: :muted)) { "Health" }
    end)
  end

  # @label Overlay
  # @notes For chips on a dark hero; the text colour comes from the hero.
  def overlay
    render(Row.new(style: "padding: 1.5rem; border-radius: 1rem; background: var(--color-foreground); color: var(--color-background)") do |r|
      r.render(Components::UI::Pill.new(variant: :overlay)) { "12 partners" }
      r.render(Components::UI::Pill.new(variant: :overlay)) { "Online" }
    end)
  end

  class Row < Phlex::HTML
    def initialize(style: nil)
      super()
      @style = style
    end

    def view_template(&)
      div(style: "display: flex; flex-wrap: wrap; gap: 0.5rem; #{@style}") { yield(self) }
    end
  end
end
