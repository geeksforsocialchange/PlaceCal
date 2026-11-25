# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::LocationRule do
  ParityEvent = Struct.new(:location) do
    def location?
      location.present?
    end

    def postcode
      CalendarImporter::Events::Base.postcode_in(location)
    end
  end

  texts = {
    "no text" => nil,
    "blank text" => "",
    "whitespace" => "   ",
    "a link" => "https://zoom.example/j/123",
    "a padded link" => "  https://zoom.example/j/123  ",
    "a valid address" => "Oak Hall, 5 Elm Street, ZZMB 1RS",
    "a postcode only" => "ZZMB 1RS",
    "a venue name first" => "Riverside Community Hub, 1 River Road, ZZMB 1RS",
    "the hub's building" => "1 River Road, Millbrook, ZZMB 1RS",
    "the library's building" => "10 Heritage Lane, Oldtown, ZZMB 2OT",
    "unreadable text" => "The park by the river",
    "a trailing comma" => "Oak Hall, 5 Elm Street, ZZMB 1RS, "
  }

  defaults = {
    "no default location" => -> {},
    "a matchable partner" => -> { Partner.find_by!(name: "Riverside Community Hub") },
    "a partner with event matching off" => -> { create(:oldtown_library, can_be_assigned_events: false) },
    "a partner with no address" => -> { build(:partner, address: nil) }
  }

  before do
    create(:riverside_ward)
    create(:oldtown_ward)
    create(:riverside_community_hub)
  end

  def outcome(result, reason)
    [result.place, result.match, result.address&.all_address_lines, reason]
  end

  def resolver_outcome(strategy, default_location, text)
    calendar = build(:calendar, strategy:)
    calendar.place = default_location
    resolver = CalendarImporter::LocationResolver.new(calendar, ParityEvent.new(text))
    outcome(resolver.resolve, resolver.unreadable_address_reason)
  end

  def rule_outcome(default_location, text, room_number:)
    rule = described_class.new(location: text, postcode: CalendarImporter::Events::Base.postcode_in(text), default_location:, room_number:)
    outcome(rule.result, rule.unreadable_address_reason)
  end

  defaults.each do |default_name, default_location|
    texts.each do |text_name, text|
      it "matches event_override for #{text_name} with #{default_name}" do
        default = instance_exec(&default_location)

        expect(rule_outcome(default, text, room_number: false)).to eq(resolver_outcome("event_override", default, text))
      end

      next if default_name == "no default location"

      it "matches room_number with the room flag for #{text_name} with #{default_name}" do
        default = instance_exec(&default_location)

        expect(rule_outcome(default, text, room_number: true)).to eq(resolver_outcome("room_number", default, text))
      end
    end
  end
end
