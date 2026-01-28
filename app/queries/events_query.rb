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
  def call(period:, repeating: DEFAULT_REPEATING, sort: DEFAULT_SORT, partner: nil, place: nil, neighbourhood_id: nil)
    # rubocop:enable Metrics/ParameterLists
    events = base_scope
    events = events.by_partner(partner) if partner
    events = events.in_place(place) if place
    events = filter_by_neighbourhood(events, neighbourhood_id) if neighbourhood_id.present?
    events = filter_by_repeating(events, repeating)
    events = filter_by_period(events, period)
    apply_sort(events, sort)
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

  # Returns neighbourhoods that have events, with counts
  def neighbourhoods_with_counts
    partner_ids = base_scope.distinct.pluck(:partner_id).compact
    return [] if partner_ids.empty?

    # Find neighbourhoods where partners have addresses or service areas
    Neighbourhood
      .where(id: neighbourhood_ids_for_partners(partner_ids))
      .order(:name)
      .map { |n| { neighbourhood: n, count: count_partners_in_neighbourhood(n.id, partner_ids) } }
  end

  private

  def base_scope
    @base_scope ||= Event.for_site(@site).includes(:place, :partner)
  end

  # Filter events by neighbourhood via partner's address or service areas
  def filter_by_neighbourhood(events, neighbourhood_id)
    partner_ids_in_neighbourhood = Partner
                                   .left_joins(:address, :service_areas)
                                   .where(
                                     'addresses.neighbourhood_id = :id OR service_areas.neighbourhood_id = :id',
                                     id: neighbourhood_id
                                   )
                                   .distinct
                                   .pluck(:id)

    events.where(partner_id: partner_ids_in_neighbourhood)
  end

  def filter_by_period(events, period)
    case period
    when 'future'
      future_events = events.future(@day)
      @truncated = future_events.count > FUTURE_LIMIT
      future_events.limit(FUTURE_LIMIT)
    when 'week'
      events.find_next_7_days(@day)
    else
      events.find_by_day(@day)
    end
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

  # Helper: count how many of these partners are in a neighbourhood
  def count_partners_in_neighbourhood(neighbourhood_id, partner_ids)
    Partner
      .where(id: partner_ids)
      .left_joins(:address, :service_areas)
      .where(
        'addresses.neighbourhood_id = :id OR service_areas.neighbourhood_id = :id',
        id: neighbourhood_id
      )
      .distinct
      .count
  end
end
