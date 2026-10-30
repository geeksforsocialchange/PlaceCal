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

  # The other sizes: `:item` heads one card in a list of features, `:card` a card or panel, `:title` and `:display` a marketing page's sections.
  # @label Sizes
  def sizes
    render(Sizes.new)
  end

  # `tone: :strong` is the darker ink on a coloured band; `:inherit` takes the colour of a card around it. `balance: true` evens out the lines of a wrapping heading.
  # @label Tone and balance
  def tone_and_balance
    render(Components::UI::Card.new(variant: :highlight)) do
      render(Components::UI::Heading.new(size: :display, tone: :inherit, balance: true, spacing: :none)) { "Ready to bring PlaceCal to your neighbourhood?" }
    end
  end

  # `spacing:` drops the top margin and sets the space below from the layout scale (`:none`, `:xs`, `:sm`, `:md`, `:lg` or `:xl`).
  # @label Spacing
  def spaced
    render(Spaced.new)
  end

  class Sizes < Phlex::HTML
    def view_template
      %i[display title section subhead card item].each do |size|
        render(Components::UI::Heading.new(size:, spacing: :sm)) { "A #{size} heading" }
      end
    end
  end

  class Spaced < Phlex::HTML
    def view_template
      render(Components::UI::Heading.new(spacing: :md)) { "Frequently asked questions" }
      p(class: "my-0") { "The paragraph starts one :md step under the heading." }
    end
  end
end
