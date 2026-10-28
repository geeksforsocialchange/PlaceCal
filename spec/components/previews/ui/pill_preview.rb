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
    render(Row.new(css: "p-6 rounded-card bg-foreground text-background") do |r|
      r.render(Components::UI::Pill.new(variant: :overlay)) { "12 partners" }
      r.render(Components::UI::Pill.new(variant: :overlay)) { "Online" }
    end)
  end

  class Row < Phlex::HTML
    def initialize(css: nil)
      super()
      @css = css
    end

    def view_template(&)
      div(class: ["flex flex-wrap gap-2", @css].compact.join(" ")) { yield(self) }
    end
  end
end
