# frozen_string_literal: true

class Shared::OpeningTimePreview < Lookbook::Preview
  # @label One day
  def default
    render Components::Shared::OpeningTime.new(day: "Monday", opens: "9am", closes: "5pm")
  end
end
