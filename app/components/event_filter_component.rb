# frozen_string_literal: true

class EventFilterComponent < ViewComponent::Base
  attr_reader :pointer, :period, :sort, :repeating, :today_url

  # rubocop:disable Metrics/ParameterLists
  def initialize(pointer:, period:, sort:, repeating:, today_url:, today: false)
    super()
    @pointer = pointer
    @period = period
    @sort = sort || 'time'
    @repeating = repeating
    @today_url = today_url
    @today = today
  end
  # rubocop:enable Metrics/ParameterLists

  def today?
    @today
  end
end
