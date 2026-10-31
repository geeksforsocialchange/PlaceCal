# frozen_string_literal: true

class UI::StatPreview < Lookbook::Preview
  # @label Stats in a grid
  # @notes A figure over its label on a card. Format the figure before passing it in, such as with `number_to_delimited`.
  def stats
    render Components::UI::Grid.new(cols: { base: 2, lg: 4 }) do
      safe_join([%w[12 Partnerships], ["1,284", "Partners"], %w[316 Events], %w[48 Neighbourhoods]].map do |value, label|
        render(Components::UI::Stat.new(value:, label:))
      end)
    end
  end
end
