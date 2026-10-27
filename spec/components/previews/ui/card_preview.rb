# frozen_string_literal: true

# @display context directory
class UI::CardPreview < Lookbook::Preview
  # @label Variants
  # @notes `:outlined` is the default; `:featured` sets one card apart from outlined ones;
  #   `:panel` groups a sidebar section or a filter form; `:highlight` is a call to action.
  def variants
    render(Grid.new do |g|
      %i[outlined featured panel highlight].each do |variant|
        g.render(Components::UI::Card.new(variant:)) do
          g.strong { ":#{variant}" }
          g.p(style: "margin: 0.5rem 0 0") { "A short line of card text." }
        end
      end
    end)
  end

  # @label Link
  # @notes With `href` the whole card is a link that lifts on hover.
  def link
    render(Grid.new do |g|
      g.render(Components::UI::Card.new(href: "#")) { "Community groups" }
    end)
  end

  class Grid < Phlex::HTML
    def view_template(&)
      div(style: "display: grid; grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr)); gap: 1rem; max-width: 60rem") { yield(self) }
    end
  end
end
