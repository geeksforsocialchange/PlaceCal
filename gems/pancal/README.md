# PanCal

"Pandoc for events" — a plain Ruby library that converts messy event sources
into standardised [schema.org](https://schema.org/Event) or iCalendar data:

```
readers (12 messy sources) ──→ canonical PanCal events ──→ writers (schema.org JSON-LD, ics, …)
```

Event feeds in the wild are a mess: scraped LD+JSON, quirky ICS exports,
vendor APIs (Eventbrite, TicketSource, Ticket Tailor), HTML-embedded JSON
(Wix, Squarespace), GraphQL endpoints (Resident Advisor). PanCal reads them
all into one canonical event model, from which standard formats can be
written. (Writers land in a later phase; the canonical model and all readers
are here now.)

PanCal is the parsing engine behind [PlaceCal](https://placecal.org)'s
calendar importer, extracted so it can also be used standalone with no Rails
dependency.

## Usage

```ruby
require 'pancal'

source = PanCal::Source.new(
  url:           'https://www.eventbrite.com/o/example-123',
  reader:        :auto,     # or a reader key, e.g. 'eventbrite'
  token:         nil,       # API-based readers (ticketsource, tickettailor, eventbrite)
  last_checksum: nil        # skip-if-unchanged support
)

result = PanCal.read(source)

result.events      # => [PanCal::Event, ...] canonical events
result.checksum    # => String — persist it yourself; PanCal never mutates caller state
result.changed?    # => Boolean (checksum vs source.last_checksum)
result.reader_key  # => 'eventbrite'

PanCal.detect(source) # => reader class (raises PanCal::UnsupportedFeed etc.)
PanCal.readers        # => list of reader classes
```

Events expose `uid`, `summary`, `description`, `dtstart`, `dtend`, `rrule`,
`occurrences_between(from, to)`, `location`, `postcode`, `has_location?`,
`online_meeting_url`, `publisher_url`, `private?` and `recurring_event?`.

## Configuration

```ruby
PanCal.logger = Logger.new($stderr)   # defaults to a null logger
PanCal.default_time_zone = 'Europe/London'
```

## Errors

All errors subclass `PanCal::Error` and carry a machine-readable `code`
symbol (`:not_found`, `:forbidden`, `:unreachable`, `:unreadable`,
`:unsupported`, …). `PanCal::InaccessibleFeed` also carries `http_status`
when the failure came from an HTTP response.

## Development

```
bundle install
bundle exec rspec
```

The spec suite runs with no Rails and no database; HTTP interactions replay
from VCR cassettes in `spec/fixtures/vcr_cassettes`.
