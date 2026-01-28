# frozen_string_literal: true

# Query object for filtering and sorting events
#
# @example Basic usage
#   EventsQuery.new(site: current_site).call(period: 'week')
#
# @example With filters
#   EventsQuery.new(site: current_site, day: Date.today).call(
#     period: 'week',
#     neighbourhood_id: 123,
#     sort: 'time'
#   )
#
# @example For a partner's events (used on partner show page)
#   EventsQuery.new(site: nil, day: Date.today).call(
#     period: 'week',
#     partner_or_place: partner,
#     sort: 'time'
#   )
#
class EventsQuery
  DEFAULT_REPEATING = 'on'
  DEFAULT_SORT = 'time'
  FUTURE_LIMIT = 50

  def initialize(site:, day: Time.zone.today)
    @site = site
    @day = day
    @truncated = false
  end

  attr_reader :truncated

  # Returns events filtered and sorted according to parameters
  # rubocop:disable Metrics/ParameterLists
  def call(period:, repeating: DEFAULT_REPEATING, sort: DEFAULT_SORT, partner: nil, place: nil,
           partner_or_place: nil, neighbourhood_id: nil, limit: nil)
    # rubocop:enable Metrics/ParameterLists
    events = base_scope
    events = events.by_partner(partner) if partner
    events = events.in_place(place) if place
    events = events.by_partner_or_place(partner_or_place) if partner_or_place
    events = filter_by_neighbourhood(events, neighbourhood_id) if neighbourhood_id.present?
    events = filter_by_repeating(events, repeating)
    events = filter_by_period(events, period, limit)
    apply_sort(events, sort)
  end

  # Returns filtered events as a flat relation (no grouping), useful for iCal feeds
  def for_ical
    base_scope.ical_feed
  end

  def future_count
    base_scope.future(@day).count
  end

  def next_7_days_count
    base_scope.find_next_7_days(@day).count
  end

  def next_event_after(day)
    base_scope.future(day).first
  end

  # Returns neighbourhoods that have events, with event counts for the given period
  def neighbourhoods_with_counts(period: 'future')
    events_for_period = events_in_period(period)
    partner_ids = events_for_period.distinct.pluck(:partner_id).compact
    return [] if partner_ids.empty?

    # Find neighbourhoods where partners have addresses or service areas
    Neighbourhood
      .where(id: neighbourhood_ids_for_partners(partner_ids))
      .order(:name)
      .map { |n| { neighbourhood: n, count: count_events_in_neighbourhood(n.id, events_for_period) } }
  end

  private

  def base_scope
    @base_scope ||= if @site
                      Event.for_site(@site).includes(:place, :partner)
                    else
                      Event.includes(:place, :partner)
                    end
  end

  # Filter events by neighbourhood based on where the event physically takes place:
  # 1. Event's own address neighbourhood (if event has its own address), OR
  # 2. Event's partner's address neighbourhood (if event uses partner's address)
  # This shows events happening IN the neighbourhood, not events from partners based there.
  def filter_by_neighbourhood(events, neighbourhood_id)
    events
      .left_joins(:address, partner: :address)
      .where(
        '(events.address_id IS NOT NULL AND addresses.neighbourhood_id = :id) OR ' \
        '(events.address_id IS NULL AND addresses_partners.neighbourhood_id = :id)',
        id: neighbourhood_id
      )
      .distinct
  end

  def filter_by_period(events, period, limit = nil)
    events = case period
             when 'future'
               future_events = events.future(@day)
               @truncated = future_events.count > FUTURE_LIMIT
               future_events.limit(FUTURE_LIMIT)
             when 'week'
               events.find_next_7_days(@day)
             else
               events.find_by_day(@day)
             end

    limit ? events.limit(limit) : events
  end

  def filter_by_repeating(events, repeating)
    case repeating
    when 'off' then events.one_off_events_only
    when 'last' then events.one_off_events_first
    else events
    end
  end

  def apply_sort(events, sort)
    if sort == 'summary'
      { Time.zone.today => events.sort_by_summary }
    else
      events.distinct.sort_by_time.group_by_day(&:dtstart)
    end
  end

  # Helper: get all neighbourhood IDs where these partners have presence
  def neighbourhood_ids_for_partners(partner_ids)
    address_neighbourhood_ids = Address
                                .joins(:partners)
                                .where(partners: { id: partner_ids })
                                .pluck(:neighbourhood_id)

    service_area_neighbourhood_ids = ServiceArea
                                     .where(partner_id: partner_ids)
                                     .pluck(:neighbourhood_id)

    (address_neighbourhood_ids + service_area_neighbourhood_ids).uniq
  end

  # Helper: get events for a specific period
  def events_in_period(period)
    case period
    when 'future'
      base_scope.future(@day)
    when 'week'
      base_scope.find_next_7_days(@day)
    else
      base_scope.find_by_day(@day)
    end
  end

  # Helper: count events in a neighbourhood (using same logic as filter_by_neighbourhood)
  def count_events_in_neighbourhood(neighbourhood_id, events)
    filter_by_neighbourhood(events, neighbourhood_id).count
  end
end
