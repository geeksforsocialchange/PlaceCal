# frozen_string_literal: true

# @display context directory
class UI::KickerPreview < Lookbook::Preview
  # @label Tones
  # @notes `:muted` is the usual kicker; `:accent` names a pricing tier; `:foreground` heads a footer column; `:strong` sits on a secondary band; `:faded` dims a dark band's colour.
  def tones
    render(Tones.new)
  end

  # @label Above a heading
  # @notes `spacing:` takes the same steps as `UI::Heading`, here `:xs` above a section heading.
  def above_heading
    render(AboveHeading.new)
  end

  class Tones < Phlex::HTML
    def view_template
      %i[muted accent foreground strong inherit].each do |tone|
        render(Components::UI::Kicker.new(tone:, spacing: :sm)) { "#{tone} kicker" }
      end
      div(class: "bg-foreground text-background p-4") { render(Components::UI::Kicker.new(tone: :faded)) { "faded kicker" } }
    end
  end

  class AboveHeading < Phlex::HTML
    def view_template
      render(Components::UI::Kicker.new(tone: :muted, spacing: :xs)) { "Who it's for" }
      render(Components::UI::Heading.new(spacing: :none)) { "Built for every kind of community" }
    end
  end
end
