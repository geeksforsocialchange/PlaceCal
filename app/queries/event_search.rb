# frozen_string_literal: true

# Event search by real-world place, date range, keyword and category, for the
# public GraphQL API and the MCP server.
class EventSearch
  class Error < StandardError; end

  UK_POSTCODE = /\A[A-Z]{1,2}\d[A-Z\d]?\d[A-Z]{2}\z/

  # @param from [Time] earliest start; defaults to the start of today
  # @param to [Time, nil] start cut-off
  # @param filters [Hash] optional :postcode (UK, resolved to its ward), :place (a ward,
  #   district, county or region name), :query (text in titles and descriptions), :category
  def initialize(from: nil, to: nil, **filters)
    filters.assert_valid_keys(:postcode, :place, :query, :category)
    @from = from || Time.zone.now.beginning_of_day
    @to = to
    @postcode, @place, @query, @category = filters.values_at(:postcode, :place, :query, :category).map(&:presence)
  end

  # @return [ActiveRecord::Relation<Event>]
  # @raise [EventSearch::Error] for an unknown postcode, place or category
  def call
    events = Event.sort_by_time.where(dtstart: @from..)
    events = events.where(dtstart: ...@to) if @to
    events = in_neighbourhoods(events, neighbourhoods) if @postcode || @place
    events = matching_text(events) if @query
    events = events.with_tags([category_tag]) if @category
    events
  end

  # @return [Array<Neighbourhood>] the areas the postcode or place resolved to
  def neighbourhoods
    @neighbourhoods ||= [*postcode_neighbourhood, *place_neighbourhoods]
  end

  private

  # Held in the area, or by an organiser based or working there when the event has no address
  def in_neighbourhoods(events, areas)
    ids = areas.flat_map(&:subtree_ids)
    located = Event.left_joins(:address, organiser: :address)
                   .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IN (?)', ids)
    served = Event.where(address_id: nil, organiser_id: ServiceArea.where(neighbourhood_id: ids).select(:partner_id))
    events.where(id: located.select(:id)).or(events.where(id: served.select(:id)))
  end

  def matching_text(events)
    pattern = "%#{Event.sanitize_sql_like(@query.strip)}%"
    events.where('events.summary ILIKE :pattern OR events.description ILIKE :pattern', pattern:)
  end

  def postcode_neighbourhood
    return [] unless @postcode

    postcode = @postcode.upcase.delete(' ')
    raise Error, "#{@postcode} isn't a UK postcode" unless postcode.match?(UK_POSTCODE)

    neighbourhood = Neighbourhood.find_by(id: cached_postcode_neighbourhood_id(postcode))
    raise Error, "No PlaceCal area found for #{@postcode}" unless neighbourhood

    [neighbourhood]
  end

  # Wards rarely move, so a lookup is kept for a month; a miss for a day
  def cached_postcode_neighbourhood_id(postcode)
    key = "event_search/postcode/#{postcode}"
    cached = Rails.cache.read(key)
    return cached unless cached.nil?

    result = Geocoder.search(postcode).first&.data
    id = (result && Neighbourhood.find_from_postcodesio_response(result)&.id) || 0
    Rails.cache.write(key, id, expires_in: id.zero? ? 1.day : 30.days)
    id
  end

  def place_neighbourhoods
    return [] unless @place

    matches = Neighbourhood.where('lower(name) = ?', @place.strip.downcase)
    current = matches.where(release_date: Neighbourhood::LATEST_RELEASE_DATE)
    found = (current.exists? ? current : matches).to_a
    raise Error, "No PlaceCal area called #{@place}. Try a UK ward, district or county name, or a postcode" if found.empty?

    found
  end

  def category_tag
    Category.find_by('lower(name) = ?', @category.strip.downcase) ||
      raise(Error, "No category called #{@category}. Categories: #{Category.order(:name).pluck(:name).join(', ')}")
  end
end
