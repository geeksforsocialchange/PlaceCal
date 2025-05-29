# frozen_string_literal: true

class OpeningTimes < ViewComponent::Base
  def initialize(times:)
    super()
    @times = times
  end
end
