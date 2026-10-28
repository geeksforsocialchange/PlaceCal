# frozen_string_literal: true

class UI::ClusterPreview < Lookbook::Preview
  # @label Buttons
  # @notes A row that wraps when it runs out of room. `gap:` is `:none`, `:xs`, `:sm`, `:md`, `:lg` or `:xl`; `row_gap:` defaults to the same.
  def buttons
    render Components::UI::Cluster.new(gap: :md) do
      safe_join(%w[Previous Next Back].map { |label| render(Components::UI::Button.new(variant: :outline, href: "#")) { label } })
    end
  end

  # @label Pills, centred
  # @notes `justify:` is `:start`, `:center`, `:end` or `:between`; `as: :ul` renders an unstyled list.
  def pills
    render Components::UI::Cluster.new(gap: :sm, justify: :center, as: :ul) do
      safe_join(%w[Arts Health Food Sport Music Advice].map { |name| tag.li { render(Components::UI::Pill.new(variant: :tag, href: "#")) { name } } })
    end
  end
end
