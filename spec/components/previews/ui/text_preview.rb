# frozen_string_literal: true

# @display context directory
class UI::TextPreview < Lookbook::Preview
  # @label Body
  # @notes Running text at the base size; `measure:` caps the line length (`:prose`, `:prose_md`, `:prose_lg` or `:none`).
  def body
    render(Components::UI::Text.new(measure: :prose)) do
      "PlaceCal brings together what's on in a neighbourhood: every group, venue and event, in one place, kept up to date from the calendars people already use."
    end
  end

  # @label Lede
  # @notes The smaller paragraph under a section heading or on a card.
  def lede
    render(Components::UI::Text.new(variant: :lede, tone: :muted, measure: :prose)) do
      "Whether you run a community group or a city-wide service, PlaceCal helps people find what's happening near them."
    end
  end

  # @label Tones
  # @notes The colour comes from the surrounding text unless `tone:` is `:foreground`, `:strong` or `:muted`.
  def tones
    render(Tones.new)
  end

  class Tones < Phlex::HTML
    def view_template
      %i[inherit foreground strong muted].each do |tone|
        render(Components::UI::Text.new(tone:)) { "A #{tone} paragraph." }
      end
    end
  end
end
