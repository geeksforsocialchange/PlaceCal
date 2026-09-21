# frozen_string_literal: true

require "rails_helper"

# Guards the contract that every parser's URL_PATTERNS stay in the shared
# Ruby/JavaScript regex subset, since they are exported verbatim to the
# browser extension via /api/v1/calendar_detection_rules and compiled there
# with JavaScript's `new RegExp(pattern, flags)`.
RSpec.describe "calendar parser detection rules" do
  # Ruby-only regex constructs that JavaScript's RegExp either rejects or
  # silently interprets differently.
  JS_UNSAFE_CONSTRUCTS = [
    '\A', '\z', '\Z', # string anchors — use ^ and $
    '\h', '\H',       # hex digit classes
    '\G',             # match start anchor
    "(?-", "(?i",     # inline flag groups (Regexp.union embeds these)
    "(?~",            # absence operator
    "[[:"             # POSIX character classes
  ].freeze

  CalendarImporter::CalendarImporter::PARSERS.each do |parser|
    describe parser.name do
      it "declares url_patterns as an array of pattern/flags hashes" do
        expect(parser.url_patterns).to be_an(Array)

        parser.url_patterns.each do |entry|
          expect(entry.keys).to contain_exactly(:pattern, :flags)
          expect(entry[:pattern]).to be_a(String)
          expect(entry[:flags]).to match(/\Ai?\z/)
        end
      end

      it "uses only JavaScript-compatible regex syntax" do
        parser.url_patterns.each do |entry|
          # must compile as a Ruby regex
          expect { Regexp.new(entry[:pattern]) }.not_to raise_error

          JS_UNSAFE_CONSTRUCTS.each do |construct|
            expect(entry[:pattern]).not_to include(construct),
                                           "#{parser.name} pattern #{entry[:pattern].inspect} contains " \
                                           "JS-unsafe construct #{construct.inspect}"
          end
        end
      end

      it "has a parser key and name when public" do
        next unless parser::PUBLIC

        expect(parser::KEY).to be_present
        expect(parser::NAME).to be_present
      end
    end
  end

  describe "allowlist_pattern derivation" do
    sample_urls = {
      "eventbrite" => "https://www.eventbrite.co.uk/o/organiser-name-12345",
      "ical" => "https://example.com/feed.ics",
      "ticketsource" => "https://www.ticketsource.co.uk/fairfield-house",
      "meetup" => "https://www.meetup.com/some-group",
      "outsavvy" => "https://www.outsavvy.com/organiser/some-org",
      "residentadvisor" => "https://ra.co/promoters/12345",
      "squarespace" => "https://example.squarespace.com/events",
      "ticket-solve" => "https://venue.ticketsolve.com/",
      "tickettailor" => "https://www.tickettailor.com/events/queerrunclub",
      "wix" => "https://user123.wixsite.com/mysite"
    }.freeze

    sample_urls.each do |key, url|
      it "matches the documented #{key} URL shape" do
        parser = CalendarImporter::CalendarImporter::PARSERS.find { |p| p::KEY == key }
        expect(parser).to be_present
        expect(parser.allowlist_pattern).to match(url)
      end
    end

    it "never matches a URL for parsers without URL patterns" do
      expect(CalendarImporter::Parsers::LdJson.allowlist_pattern).not_to match("https://example.com/anything")
    end
  end
end
