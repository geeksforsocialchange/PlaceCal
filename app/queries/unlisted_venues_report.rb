# frozen_string_literal: true

require 'csv'

# Counts upcoming events whose location text names no partner's building, grouped by building.
class UnlistedVenuesReport
  DEFAULT_LIMIT = 50
  BATCH_SIZE = 1000
  SAMPLE_WIDTH = 60
  NO_POSTCODE = '(no postcode)'
  HEADERS = ['Postcode', 'First line', 'Events', 'Calendars', 'Sample location'].freeze

  Row = Struct.new(:postcode, :first_line, :sample, :events, :calendar_ids) do
    def add(calendar_id)
      self.events += 1
      calendar_ids << calendar_id
    end

    def values
      [postcode, first_line, events, calendar_ids.size, sample]
    end
  end

  # @param limit [Integer, nil] how many venues to list; blank or not positive means DEFAULT_LIMIT
  def initialize(limit: nil)
    @limit = limit.to_i.positive? ? limit.to_i : DEFAULT_LIMIT
  end

  # @return [Integer] upcoming events with location text that is not just a link
  def total
    tally && @total
  end

  # @return [Integer] events at unlisted venues with a postcode
  def unlisted_events
    tally && @groups.each_value.sum(&:events)
  end

  # @return [Array<Row>] the busiest unlisted venues, most events first, up to the limit
  def rows
    tally && @groups.values.sort_by { |row| [-row.events, row.postcode, row.first_line.to_s.downcase] }.first(@limit)
  end

  # @return [Row] every event whose location text has no postcode
  def no_postcode
    tally && @no_postcode
  end

  # @return [String] a summary and a table aligned in columns
  def to_text
    table = [HEADERS, *(rows + [no_postcode]).map { |row| text_values(row) }]
    widths = HEADERS.each_index.map { |i| table.map { |cells| cells[i].length }.max }

    lines = table.map do |cells|
      cells.each_with_index.map { |cell, i| [2, 3].include?(i) ? cell.rjust(widths[i]) : cell.ljust(widths[i]) }.join('  ').rstrip
    end

    [
      "Upcoming events with a location: #{total}",
      "Events at venues that match no partner: #{unlisted_events}",
      "Venues that match no partner: #{@groups.size}",
      "Events with no postcode: #{no_postcode.events}",
      '',
      *lines
    ].join("\n")
  end

  # @return [String] the table as CSV with a header row
  def to_csv
    CSV.generate do |csv|
      csv << HEADERS
      (rows + [no_postcode]).each { |row| csv << row.values }
    end
  end

  private

  def tally
    @tally ||= ActiveRecord::Base.while_preventing_writes do
      keys = partner_keys
      room_calendar_ids = Calendar.where(strategy: 'room_number').pluck(:id).to_set
      @groups = {}
      @no_postcode = Row.new(nil, NO_POSTCODE, nil, 0, Set.new)
      @total = 0

      events.in_batches(of: BATCH_SIZE) do |batch|
        batch.pluck(:raw_location_from_source, :calendar_id).each do |text, calendar_id|
          text = text.squish
          next if text.match?(CalendarImporter::LocationResolver::ONLINE_LINK)

          @total += 1
          # A room number calendar's text is a room at its own venue
          count(text, calendar_id, keys) unless room_calendar_ids.include?(calendar_id)
        end
      end
      true
    end
  end

  def count(text, calendar_id, keys)
    postcode = CalendarImporter::Events::Base.postcode_in(text)
    if postcode.blank?
      @no_postcode.sample ||= text
      return @no_postcode.add(calendar_id)
    end

    components = CalendarImporter::LocationResolver.location_components(text, postcode)
    # The importer matches a partner by name as well as street, and the name is often the first line
    return if components.any? { |component| keys.include?(Address.building_key(postcode, component)) }

    first_line = components.first.to_s
    row = @groups[Address.building_key(postcode, first_line)] ||= Row.new(postcode, first_line, text, 0, Set.new)
    row.add(calendar_id)
  end

  def events
    Event.upcoming.where("TRIM(raw_location_from_source) <> ''")
  end

  def partner_keys
    Partner.joins(:address).pluck(:name, 'addresses.postcode', 'addresses.street_address')
           .each_with_object(Set.new) do |(name, postcode, street), keys|
      keys << Address.building_key(postcode, street) << Address.building_key(postcode, name)
    end
  end

  def text_values(row)
    sample = row.sample.to_s
    sample = "#{sample[0, SAMPLE_WIDTH - 3]}..." if sample.length > SAMPLE_WIDTH
    [row.postcode.to_s, row.first_line, row.events.to_s, row.calendar_ids.size.to_s, sample]
  end
end
