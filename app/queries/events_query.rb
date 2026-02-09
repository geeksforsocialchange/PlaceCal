# frozen_string_literal: true

# Query object for filtering and sorting events
#
# @example Basic usage
#   EventsQuery.new(site: current_site).call(period: 'week')
#
# @example With filters
#   EventsQuery.new(site: current_site).call(
#     period: 'week',
#     neighbourhood_id: 123,
#     sort: 'time'
#   )
#
# @example For a partner's events (used on partner show page)
#   EventsQuery.new(site: nil).call(
#     period: 'week',
#     partner_or_place: partner
#   )
#
class EventsQuery
  FUTURE_LIMIT = 50

  def initialize(site:, day: Time.zone.today)
    @site = site
    @day = day
    @truncated = false
  end

  attr_reader :truncated

  # Main entry point - returns events filtered, sorted, and grouped by day
  #
  # @param period [String] 'day', 'week', or 'future'
  # @param sort [String] 'time' (default) or 'summary'
  # @param repeating [String] 'on' (default), 'off', or 'last'
  # @param partner [Partner] filter to events by this partner
  # @param place [Partner] filter to events at this place
  # @param partner_or_place [Partner] filter to events by OR at this partner
  # @param neighbourhood_id [Integer] filter to events in this neighbourhood
  # @param limit [Integer] max number of events to return
  #
  # @return [Hash] events grouped by date { Date => [Event, ...] }
  # rubocop:disable Metrics/ParameterLists
  def call(period:, sort: 'time', repeating: 'on', partner: nil, place: nil,
           partner_or_place: nil, neighbourhood_id: nil, limit: nil)
    # rubocop:enable Metrics/ParameterLists
    events = build_filtered_scope(
      partner: partner,
      place: place,
      partner_or_place: partner_or_place,
      neighbourhood_id: neighbourhood_id,
      repeating: repeating
    )
    events = apply_period(events, period)
    events = events.limit(limit) if limit
    group_and_sort(events, sort)
  end

  # Returns the base scope as a flat relation for further chaining
  #
  # @return [ActiveRecord::Relation<Event>]
  def scope
    base_scope
  end

  # Returns events as a flat relation for iCal feeds (no grouping)
  def for_ical
    base_scope.ical_feed
  end

  # Efficient count for a period (no grouping or sorting)
  #
  # @param period [String] 'day', 'week', or 'future'
  # @return [Integer]
  def count_for_period(period)
    apply_period(base_scope, period).count
  end

  # Count methods for determining default period
  def future_count
    base_scope.future(@day).count
  end

  def next_7_days_count
    base_scope.find_next_7_days(@day).count
  end

  def next_event_after(day)
    base_scope.future(day).first
  end

  # Returns neighbourhoods that have events, with counts for the given period
  # Used for filter dropdowns
  #
  # @param period [String] 'day', 'week', or 'future'
  # @return [Array<Hash>] array of { neighbourhood: Neighbourhood, count: Integer }
  def neighbourhoods_with_counts(period: 'future')
    events = apply_period(base_scope, period)
    partner_ids = events.distinct.pluck(:partner_id).compact
    return [] if partner_ids.empty?

    neighbourhood_ids = neighbourhood_ids_for_partners(partner_ids)
    return [] if neighbourhood_ids.empty?

    # Single grouped query instead of N separate counts
    counts = events
             .left_joins(:address, partner: :address)
             .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IN (?)', neighbourhood_ids)
             .group('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id)')
             .distinct
             .count

    Neighbourhood
      .where(id: neighbourhood_ids)
      .order(:name)
      .map { |n| { neighbourhood: n, count: counts[n.id] || 0 } }
  end

  private

  # ===================
  # Base Scope
  # ===================

  def base_scope
    @base_scope ||= @site ? events_for_site.includes(:place, :partner) : Event.includes(:place, :partner)
  end

  # Inline of Event.for_site - finds events belonging to partners in this site
  # When site has tags: only events from tagged partners (no address fallback)
  # When site has no tags: events from site partners OR events with address in site neighbourhoods
  def events_for_site
    partner_records = PartnersQuery.new(site: @site).call.reorder(nil).includes(:address).to_a
    partner_ids = partner_records.map(&:id)

    if @site.tags.any?
      # Site has tags - only show events from partners with those tags
      # Address fallback matches partner name/postcode (legacy behavior)
      partner_names = partner_records.map { |p| p.name.downcase }
      partner_postcodes = partner_records.filter_map(&:address).map { |a| a.postcode.downcase }

      Event
        .left_joins(:address)
        .where(
          'partner_id IN (:partner_ids) OR ' \
          '(lower(addresses.street_address) IN (:partner_names) AND ' \
          'lower(addresses.postcode) IN (:partner_postcodes))',
          partner_ids: partner_ids,
          partner_names: partner_names,
          partner_postcodes: partner_postcodes
        )
    else
      # No site tags - events from partners OR events with address in site neighbourhoods
      site_neighbourhood_ids = @site.owned_neighbourhood_ids

      Event
        .left_joins(:address)
        .where(
          'partner_id IN (:partner_ids) OR addresses.neighbourhood_id IN (:neighbourhood_ids)',
          partner_ids: partner_ids,
          neighbourhood_ids: site_neighbourhood_ids
        )
    end
  end

  # ===================
  # Filtering
  # ===================

  def build_filtered_scope(partner:, place:, partner_or_place:, neighbourhood_id:, repeating:)
    events = base_scope
    events = events.by_partner(partner) if partner
    events = events.in_place(place) if place
    events = events.by_partner_or_place(partner_or_place) if partner_or_place
    events = filter_by_neighbourhood(events, neighbourhood_id) if neighbourhood_id.present?
    apply_repeating_filter(events, repeating)
  end

  # Filter by physical location of event (event address, or partner address if no event address)
  def filter_by_neighbourhood(events, neighbourhood_id)
    events
      .left_joins(:address, partner: :address)
      .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) = ?', neighbourhood_id)
      .distinct
  end

  def apply_repeating_filter(events, repeating)
    case repeating
    when 'off' then events.one_off_events_only
    when 'last' then events.one_off_events_first
    else events
    end
  end

  # ===================
  # Period Selection
  # ===================

  def apply_period(events, period)
    case period
    when 'future' then apply_future_period(events)
    when 'week' then events.find_next_7_days(@day)
    else events.find_by_day(@day)
    end
  end

  def apply_future_period(events)
    future_events = events.future(@day)
    @truncated = future_events.count > FUTURE_LIMIT
    future_events.limit(FUTURE_LIMIT)
  end

  # ===================
  # Sorting & Grouping
  # ===================

  def group_and_sort(events, sort)
    if sort == 'summary'
      { Time.zone.today => events.sort_by_summary }
    else
      events.distinct.sort_by_time.group_by_day(&:dtstart)
    end
  end

  # ===================
  # Neighbourhood Helpers
  # ===================

  # Get all neighbourhood IDs where these partners have presence (address or service area)
  def neighbourhood_ids_for_partners(partner_ids)
    address_ids = Address.joins(:partners).where(partners: { id: partner_ids }).pluck(:neighbourhood_id)
    service_area_ids = ServiceArea.where(partner_id: partner_ids).pluck(:neighbourhood_id)
    (address_ids + service_area_ids).uniq
  end
end
