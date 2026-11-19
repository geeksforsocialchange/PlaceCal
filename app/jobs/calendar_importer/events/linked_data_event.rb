# frozen_string_literal: true

module CalendarImporter::Events
  class LinkedDataEvent < Base
    imports title: 'name', description: 'description', start_time: 'startDate', end_time: 'endDate', repeats: nil,
            location: %w[location.address location.name], webpage: 'url', online_link: nil, spaces_available: nil, status: 'eventStatus',
            image: 'image', source_categories: 'keywords', source_organiser: %w[organizer performer],
            ticket_url: 'offers.url', price: %w[offers.price offers.lowPrice offers.priceCurrency], sold_out: 'offers.availability'

    STATUSES = { 'EventCancelled' => 'cancelled', 'EventPostponed' => 'postponed' }.freeze
    SCHEMA_ORG = %r{\A(https?://schema\.org/|schema:)}
    # Not in Parsers::Base::CONTEXT, so compacting leaves them under their full IRI
    KEYWORDS = 'http://schema.org/keywords'
    PERFORMER = 'http://schema.org/performer'
    OFFERS = 'http://schema.org/offers'
    PRICE = 'http://schema.org/price'
    LOW_PRICE = 'http://schema.org/lowPrice'
    HIGH_PRICE = 'http://schema.org/highPrice'
    PRICE_CURRENCY = 'http://schema.org/priceCurrency'
    AVAILABILITY = 'http://schema.org/availability'
    SOLD_OUT = %w[SoldOut OutOfStock].freeze

    attr_reader :uid, :start_time, :end_time, :summary, :description, :location

    alias dtstart start_time
    alias dtend end_time

    def initialize(data)
      super

      @url = data['url']
      @description = data['description']
      @start_time = parse_timestamp(read_value_of(data, 'start_date'))
      @end_time = parse_timestamp(read_value_of(data, 'end_date'))
      @summary = data['name']
      @location = extract_location(data)
      @event_status = data['http://schema.org/eventStatus']

      # Repeating events share a URL, so we need to add the starttime as a param.
      # Otherwise, PlaceCal will assume they're all the same event and update instead of create.
      @uid = "#{@url}?start=#{@start_time}"
    end

    def read_value_of(data, field_name)
      field_data = data[field_name]
      return unless field_data

      field_data['@value']
    end

    def parse_timestamp(value)
      DateTime.parse value.to_s
    rescue Date::Error
      nil
    end

    def extract_location(data)
      loc = data['location']
      return if loc.blank?

      address = loc['address']
      # Some sites (dice.fm) give the address as one line of text, postcode included
      return address.strip.presence || loc['name'] if address.is_a?(String)
      return loc['name'] unless address.is_a?(Hash)

      # Build full address from components
      components = [
        address['street_address'],
        address['address_locality'],
        address['address_region'],
        address['postal_code']
      ].compact_blank

      components.join(', ').presence || loc['name']
    end

    def valid?
      @url.present? &&
        @start_time.present? &&
        # @end_time.present &&
        @summary.present?
    end

    def in_future?
      @start_time.present? && (@start_time > DateTime.now)
    end

    # eventStatus is optional; a postponed event keeps its old startDate, so it's shown on that date as postponed
    def status
      value = @event_status.is_a?(Hash) ? @event_status['@id'] : @event_status
      STATUSES.fetch(value.to_s.sub(SCHEMA_ORG, ''), 'scheduled')
    end

    def publisher_url
      @event['url']
    end

    # schema.org image is a URL, an ImageObject, or a list of either
    def image_url
      image = Array.wrap(@event['image_url']).first
      image.is_a?(Hash) ? image['@id'] || image['url'] : image
    end

    # keywords is one comma-separated string, or a list of strings or DefinedTerms
    def source_categories
      keywords = @event[KEYWORDS]
      return keywords.split(',') if keywords.is_a?(String)

      Array.wrap(keywords).flat_map { |keyword| named(keyword) }
    end

    # Older OutSavvy pages name the organiser only as a performer; a performer that is a person or band is the act
    def source_organiser
      names_of(@event['organiser']) || names_of(Array.wrap(@event[PERFORMER]).select { |node| organization?(node) })
    end

    def ticket_url
      (offers + single_offers).filter_map { |offer| offer['url'].presence }.first
    end

    # Each ticket's own price, preferring tickets still on sale; an AggregateOffer's lowPrice only without them
    def price_from
      priced = single_offers.select { |offer| value_of(offer[PRICE]).present? }
      on_sale = priced.reject { |offer| sold_out_offer?(offer) }
      prices = (on_sale.presence || priced).filter_map { |offer| Base.price(value_of(offer[PRICE])) }
      prices = offers.reject { |offer| placeholder_range?(offer) }.filter_map { |offer| Base.price(value_of(offer[LOW_PRICE])) } if prices.empty?
      prices.min
    end

    def price_currency
      (single_offers + offers).filter_map { |offer| value_of(offer[PRICE_CURRENCY]).presence }.first
    end

    # Sold out when every stated availability is SoldOut or OutOfStock, which OutSavvy also gives once sales close
    def sold_out
      stated = offers.filter_map { |offer| availability(offer) }
      stated = single_offers.filter_map { |offer| availability(offer) } if stated.empty?
      stated.all? { |value| SOLD_OUT.include?(value) } if stated.any?
    end

    private

    def offers
      Array.wrap(@event[OFFERS]).grep(Hash)
    end

    # The tickets inside each AggregateOffer, and each offer that has none
    def single_offers
      offers.flat_map { |offer| Array.wrap(offer[OFFERS]).grep(Hash).presence || [offer] }
    end

    # OutSavvy sends a range of 0 to 0 with no tickets when it has nothing to sell
    def placeholder_range?(offer)
      [LOW_PRICE, HIGH_PRICE].all? { |key| Base.price(value_of(offer[key]))&.zero? }
    end

    def sold_out_offer?(offer)
      SOLD_OUT.include?(availability(offer))
    end

    def availability(offer)
      value_of(offer[AVAILABILITY]).to_s.sub(SCHEMA_ORG, '').presence
    end

    def value_of(value)
      value.is_a?(Hash) ? value['@value'] || value['@id'] : value
    end

    def names_of(nodes)
      Base.clean_list(Array.wrap(nodes).flat_map { |node| named(node) }).join(', ').presence
    end

    def organization?(node)
      node.is_a?(Hash) && Array.wrap(node['@type']).any? { |type| type.to_s.sub(SCHEMA_ORG, '') == 'Organization' }
    end

    def named(node)
      return [node] unless node.is_a?(Hash)

      Array.wrap(node.key?('@value') ? node['@value'] : node['name']).map { |name| name.is_a?(Hash) ? name['@value'] : name }
    end
  end
end
