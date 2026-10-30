# frozen_string_literal: true

class UI::ClusterPreview < Lookbook::Preview
  # @label Buttons
  # @notes A row that wraps when it runs out of room. `gap:` is `:none`, `:xs`, `:sm`, `:sm_md`, `:md`, `:lg` or `:xl`; `row_gap:` defaults to the same.
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

  # @label Bottom-aligned, right from xl
  # @notes `align: :end` lines up the bottoms of items. With `justify_from: :xl` the row starts left and takes `justify:` from xl; `nowrap_from: :lg` keeps it on one line from lg.
  def responsive
    render Components::UI::Cluster.new(gap: :sm_md, align: :end, justify: :end, justify_from: :xl, nowrap_from: :lg) do
      safe_join([
                  render(Components::UI::Button.new(variant: :outline, size: :lg, href: "#")) { "Apply filters" },
                  render(Components::UI::Button.new(variant: :outline, size: :sm, href: "#")) { "Clear" }
                ])
    end
  end
end
