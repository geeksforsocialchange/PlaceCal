# frozen_string_literal: true

class UI::GridPreview < Lookbook::Preview
  # @label Cards
  # @notes Equal columns: `cols:` maps `:base`, `:md` and `:lg` to a count from 1 to 4, and narrow screens get one column without `:base`. `gap:` is on the Cluster and Stack scale, `:md` by default.
  def cards
    render(Components::UI::Grid.new(cols: { md: 2, lg: 3 }) do |g|
      %w[Arts Health Food Sport Music Advice].each { |name| g.render(Components::UI::Card.new) { name } }
    end)
  end

  # @label Two columns on every screen
  def two_up
    render(Components::UI::Grid.new(cols: { base: 2, lg: 4 }, gap: :sm) do |g|
      %w[One Two Three Four].each { |name| g.render(Components::UI::Card.new(variant: :panel, padding: :sm)) { name } }
    end)
  end
end
