# frozen_string_literal: true

require 'csv'

# Lists upcoming events whose shown place or address would change if their calendar used CalendarImporter::LocationRule.
class LocationRuleReport
  BATCH_SIZE = 1000
  NONE = '(none)'
  HEADERS = ['Event ID', 'Summary', 'Calendar ID', 'Calendar', 'Strategy', 'Changes', 'Current location', 'New location'].freeze
  STRATEGY_HEADERS = ['Strategy', 'Events', 'Place changes', 'Address only'].freeze

  # What the event page shows: the venue name (Event#partner_at_location) and the event's own address
  Shown = Data.define(:place, :address) do
    def key
      [place&.id, address&.all_address_lines&.map { |line| line.squish.downcase }]
    end

    def nothing?
      place.nil? && address.nil?
    end

    def to_s
      [place&.name, address&.to_s].compact_blank.join(', ').presence || NONE
    end
  end

  Change = Data.define(:event, :current, :new) do
    def place?
      current.place != new.place
    end

    def kind
      [('place' if place?), ('address' if current.key.last != new.key.last)].compact.join(' and ')
    end
  end

  StrategyCount = Struct.new(:events, :place_changes, :address_changes)

  # @param calendar [Calendar]
  # @return [Array(Partner, Boolean)] the default location and room number flag the calendar's strategy carries over to
  def self.carried_over(calendar)
    case calendar.strategy
    when 'no_location', 'online_only' then [nil, false]
    else [calendar.place, calendar.strategy == 'room_number']
    end
  end

  # @return [Integer] upcoming events on a calendar, less those whose postcode couldn't be looked up
  def checked
    tally && @checked
  end

  # @return [Array<Change>] events whose shown location would change, by calendar name then event id
  def changes
    tally && @changes
  end

  # @return [Hash{String => StrategyCount}] events and changes for each strategy
  def by_strategy
    tally && @by_strategy
  end

  # @return [Hash{Symbol => Integer}] events the rule leaves with no place or address, by whether the organiser has an address
  def without_location
    tally && @without_location
  end

  # @return [Integer] upcoming events with no calendar, which the rule never sees
  def no_calendar
    tally && @no_calendar
  end

  # @return [Integer] events left out because the postcode lookup didn't respond
  def lookup_unavailable
    tally && @lookup_unavailable
  end

  # @return [String] the totals, a table per strategy, then the changes grouped by calendar
  def to_text
    [*summary_lines, '', *table(STRATEGY_HEADERS, strategy_rows), *calendar_lines].join("\n")
  end

  # @return [String] one row per changed event, with a header row
  def to_csv
    CSV.generate do |csv|
      csv << HEADERS
      changes.each { |change| csv << csv_values(change).map { |value| spreadsheet_safe(value) } }
    end
  end

  private

  def tally
    @tally ||= ActiveRecord::Base.while_preventing_writes do
      PostcodeLookup.cached { check_events }
      true
    end
  end

  def check_events
    @checked = @no_calendar = @lookup_unavailable = 0
    @changes = []
    @by_strategy = Hash.new { |hash, strategy| hash[strategy] = StrategyCount.new(0, 0, 0) }
    @without_location = { organiser_address: 0, no_organiser_address: 0 }
    @rules = {}
    @shown = {}

    events.find_each(batch_size: BATCH_SIZE) { |event| check(event) }
    @changes.sort_by! { |change| [change.event.calendar.name.to_s.downcase, change.event.calendar_id, change.event.id] }
  end

  def check(event)
    return @no_calendar += 1 unless event.calendar

    rule = rule_for(event)
    return @lookup_unavailable += 1 if rule.unreadable_address_reason == :lookup_unavailable

    @checked += 1
    count = @by_strategy[event.calendar.strategy]
    count.events += 1
    result = rule.result
    new = shown(result.place, result.address)
    count_without_location(event) if new.nothing?
    current = shown(event.place, event.address)
    return if current.key == new.key

    change = Change.new(event:, current:, new:)
    change.place? ? count.place_changes += 1 : count.address_changes += 1
    @changes << change
  end

  # Events in a series share their location text, so each calendar's text is worked out once
  def rule_for(event)
    text = event.raw_location_from_source.to_s.strip
    @rules[[event.calendar_id, text]] ||= begin
      default_location, room_number = self.class.carried_over(event.calendar)
      rule = CalendarImporter::LocationRule.new(location: text, postcode: CalendarImporter::Events::Base.postcode_in(text),
                                                default_location:, room_number:, save: false)
      rule.result
      rule
    end
  end

  def shown(place, address)
    @shown[[place&.id, address&.new_record?, address&.id || address&.object_id]] ||= Shown.new(place: Event.new(place:, address:).partner_at_location, address:)
  end

  def count_without_location(event)
    @without_location[event.organiser&.address ? :organiser_address : :no_organiser_address] += 1
  end

  def events
    Event.upcoming.includes(:place, :address, organiser: :address, calendar: { place: :address })
  end

  def summary_lines
    [
      "Upcoming events checked: #{checked}",
      "Would change: #{changes.size} (place: #{changes.count(&:place?)}, address only: #{changes.count { |change| !change.place? }})",
      "No place or address under the rule: #{without_location.values.sum} " \
      "(organiser has an address: #{without_location[:organiser_address]}, organiser has none: #{without_location[:no_organiser_address]})",
      "Not checked, no calendar: #{no_calendar}",
      "Not checked, postcode lookup unavailable: #{lookup_unavailable}"
    ]
  end

  def strategy_rows
    by_strategy.sort.map { |strategy, count| [strategy, count.events.to_s, count.place_changes.to_s, count.address_changes.to_s] }
  end

  # Identical changes to one series print once, with every event id, place changes first
  def calendar_lines
    changes.group_by { |change| change.event.calendar }.flat_map do |calendar, calendar_changes|
      groups = calendar_changes.sort_by.with_index { |change, i| [change.place? ? 0 : 1, i] }
                               .group_by { |change| [change.place?, change.event.summary, change.current.to_s, change.new.to_s] }
      [
        '',
        "Calendar #{calendar.id}: #{calendar.name} (#{calendar.strategy}), #{calendar_changes.size} #{calendar_changes.one? ? 'event' : 'events'}",
        *groups.map do |(place, summary, current, new), group|
          "  #{place ? '[place]' : '[address]'} #{summary} (#{group.size == 1 ? 'event' : 'events'} #{group.map { |change| change.event.id }.join(', ')}): #{current} -> #{new}"
        end
      ]
    end
  end

  def table(headers, rows)
    widths = headers.each_index.map { |i| [headers, *rows].map { |cells| cells[i].length }.max }
    [headers, *rows].map do |cells|
      cells.each_with_index.map { |cell, i| i.zero? ? cell.ljust(widths[i]) : cell.rjust(widths[i]) }.join('  ').rstrip
    end
  end

  def csv_values(change)
    event = change.event
    [event.id, event.summary, event.calendar_id, event.calendar.name, event.calendar.strategy, change.kind, change.current.to_s, change.new.to_s]
  end

  # Summaries and location text come from outside feeds, and a spreadsheet can run a cell starting with = + - @ tab or return as a formula
  def spreadsheet_safe(value)
    value.is_a?(String) && value.start_with?('=', '+', '-', '@', "\t", "\r") ? "'#{value}" : value
  end
end
