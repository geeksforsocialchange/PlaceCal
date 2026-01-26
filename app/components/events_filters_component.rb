# frozen_string_literal: true

# Filter controls for the events browser
# Renders sort, period, and repeating filter options
class EventsFiltersComponent < ViewComponent::Base
  attr_reader :period, :sort, :repeating, :site_name, :current_day

  def initialize(period:, sort:, repeating:, site_name:, current_day:)
    super()
    @period = period
    @sort = sort
    @repeating = repeating
    @site_name = site_name
    @current_day = current_day
  end

  # Form action URL preserves current date in URL
  def form_action
    "/events/#{current_day.year}/#{current_day.month}/#{current_day.day}"
  end

  def sort_options
    [
      { value: 'time', label: 'Sort by date', checked: sort == 'time' },
      { value: 'summary', label: 'Sort by name', checked: sort == 'summary' }
    ]
  end

  def period_options
    [
      { value: 'day', label: 'Daily view', checked: period == 'day' },
      { value: 'week', label: 'Weekly view', checked: period == 'week' },
      { value: 'future', label: 'Show all', checked: period == 'future' }
    ]
  end

  def repeating_options
    [
      { value: 'on', label: 'Show repeats', checked: repeating == 'on' },
      { value: 'last', label: 'Show repeats last', checked: repeating == 'last' },
      { value: 'off', label: 'Hide repeats', checked: repeating == 'off' }
    ]
  end
end
