# frozen_string_literal: true

class OpeningTimesPreview < ViewComponent::Preview
  # @label Default
  def default
    times = [
      OpenStruct.new(day: 'Monday', opens: '9:00', closes: '17:00'),
      OpenStruct.new(day: 'Tuesday', opens: '9:00', closes: '17:00'),
      OpenStruct.new(day: 'Wednesday', opens: '9:00', closes: '17:00'),
      OpenStruct.new(day: 'Thursday', opens: '9:00', closes: '17:00'),
      OpenStruct.new(day: 'Friday', opens: '9:00', closes: '17:00'),
      OpenStruct.new(day: 'Saturday', opens: '10:00', closes: '14:00'),
      OpenStruct.new(day: 'Sunday', opens: nil, closes: nil)
    ]
    render(OpeningTimes.new(times: times))
  end

  # @label Partial Week
  def partial_week
    times = [
      OpenStruct.new(day: 'Monday', opens: '10:00', closes: '16:00'),
      OpenStruct.new(day: 'Wednesday', opens: '10:00', closes: '16:00'),
      OpenStruct.new(day: 'Friday', opens: '10:00', closes: '16:00')
    ]
    render(OpeningTimes.new(times: times))
  end
end
