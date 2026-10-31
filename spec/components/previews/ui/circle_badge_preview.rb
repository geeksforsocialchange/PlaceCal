# frozen_string_literal: true

class UI::CircleBadgePreview < Lookbook::Preview
  # @label Sizes and tones
  # @notes `size:` is `:sm`, `:md` or `:lg` (`size-11`, `size-13`, `size-14`) and sets the text size with it. `tone:` is `:muted`, `:background` or `:secondary`.
  def sizes
    render Components::UI::Cluster.new(gap: :md) do
      safe_join([
                  render(Components::UI::CircleBadge.new(size: :sm, tone: :muted)) { "RH" },
                  render(Components::UI::CircleBadge.new(size: :md, tone: :background)) { "2" },
                  render(Components::UI::CircleBadge.new(size: :lg, tone: :secondary)) { "3" }
                ])
    end
  end

  # @label Growing from md
  # @notes `md_size:` gives a different size from the md breakpoint up, as on the pricing rollout steps.
  def responsive
    render(Components::UI::CircleBadge.new(size: :sm, md_size: :lg, tone: :secondary)) { "1" }
  end
end
