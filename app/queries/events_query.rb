# frozen_string_literal: true

# Query object for filtering and sorting events
# Consolidates logic previously scattered across ApplicationController and Event model
class EventsQuery
  DEFAULT_REPEATING = 'on'
  DEFAULT_SORT = 'time'

  def initialize(site:, day: Time.zone.today)
    @site = site
    @day = day
  end

  # Returns events filtered and sorted according to parameters
  # @param period [String] 'day', 'week', or 'future'
  # @param repeating [String] 'on', 'off', or 'last'
  # @param sort [String] 'time' or 'summary'
  # @param partner [Partner, nil] optional partner filter
  # @param place [Address, nil] optional place filter
  # @return [Hash] events grouped by date { Date => [Event, ...] }
  def call(period:, repeating: DEFAULT_REPEATING, sort: DEFAULT_SORT, partner: nil, place: nil)
    events = base_scope
    events = apply_location_filter(events, partner: partner, place: place)
    events = apply_repeating_filter(events, repeating)
    events = apply_period_filter(events, period)
    apply_sort(events, sort)
  end

  # Returns the count of future events (used to auto-select period)
  def future_count
    base_scope.future(@day).count
  end

  # Returns the next event after the given day
  def next_event_after(day)
    base_scope.future(day).first
  end

  private

  def base_scope
    Event.for_site(@site).includes(:place, :partner)
  end

  def apply_location_filter(events, partner:, place:)
    events = events.in_place(place) if place
    events = events.by_partner(partner) if partner
    events
  end

  def apply_period_filter(events, period)
    case period
    when 'future'
      events.future(@day)
    when 'week'
      events.find_by_week(@day)
    else
      events.find_by_day(@day)
    end
  end

  def apply_repeating_filter(events, repeating)
    case repeating
    when 'off'
      events.one_off_events_only
    when 'last'
      events.one_off_events_first
    else
      events
    end
  end

  def apply_sort(events, sort)
    if sort == 'summary'
      { Time.zone.today => events.sort_by_summary }
    else
      events.distinct.sort_by_time.group_by_day(&:dtstart)
    end
  end
end
