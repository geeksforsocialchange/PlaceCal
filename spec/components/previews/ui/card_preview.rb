# frozen_string_literal: true

# @display context directory
# @display width page
class UI::CardPreview < Lookbook::Preview
  # @label Variants
  # @notes `:outlined` is the default; `:featured` sets one card apart; `:panel` groups a sidebar section or filter form; `:highlight` is a call to action; `:cream` and `:cream_strong` are join cards.
  def variants
    render(Grid.new do |g|
      %i[outlined featured panel highlight cream cream_strong].each do |variant|
        g.render(Components::UI::Card.new(variant:)) do
          g.strong { ":#{variant}" }
          g.p(class: "mt-2 mb-0") { "A short line of card text." }
        end
      end
    end)
  end

  # @label Link
  # @notes With `href` the whole card is a link that lifts on hover.
  def link
    render(Grid.new do |g|
      ["Community groups", "Housing providers", "Social prescribers"].each { |label| g.render(Components::UI::Card.new(href: "#")) { label } }
    end)
  end

  class Grid < Phlex::HTML
    def view_template(&)
      div(class: "grid md:grid-cols-2 lg:grid-cols-3 gap-4") { yield(self) }
    end
  end
end
