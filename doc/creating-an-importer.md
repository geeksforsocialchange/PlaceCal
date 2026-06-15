# How the importer works

Calendars can be imported through the following rake tasks:

```
rails events:import_all_calendars # Imports all calendars - usually in dev environment
rails events:import_calendars[:id] # Imports one calendar - usually in a dev environment
rails events:scan_for_calendars_needing_import # Imports only updated calendars - run as a cronjob in a production environment
```

They can also be triggered in the Calendar interface in the web admin.

Feed parsing lives in the **PanCal gem** (`gems/pancal/` — "pandoc for events"),
a plain Ruby library with no Rails dependency. PlaceCal keeps the orchestration:
jobs, the Calendar state machine, and everything that needs the database
(location resolution, online address persistence).

All of the tasks above create `CalendarImporterJob`s (/app/jobs/calendar_importer_job.rb). This job is how all external URLs get turned into Events and imported into PlaceCal, with Calendars being effectively the configuration for how to import them.

1. `CalendarImporterJob` looks up each Calendar. It creates a...
2. `CalendarImporter::CalendarImporterTask` (the PlaceCal↔PanCal adapter), which builds a `PanCal::Source` from the Calendar and calls `PanCal.read`. Inside the gem...
3. `PanCal::Detector` identifies the feed type and hands it to a `PanCal::Readers::MyReader`, which queries the URL and maps the data into canonical `PanCal::Event`s. Back in PlaceCal...
4. `CalendarImporter::EventResolver` analyses each canonical event, resolves its location (`LocationResolver`) and online link (`OnlineDetector`), and saves PlaceCal Events.

The split: **parsing lives in the gem; anything touching `Partner`, `Address`,
`Event`, or `OnlineAddress` stays in PlaceCal.** PanCal never mutates caller
state — it reports the feed checksum on its result and PlaceCal persists it.

## Adding a new importer

Importers require two parts, both inside the gem:

1. A **PanCal::Readers** class, which reads a remote URL and turns it into structured data
2. A **PanCal::Events** class, which maps that data onto the canonical `PanCal::Event` contract

### PanCal::Readers

1. Create `gems/pancal/lib/pancal/readers/my_reader.rb`, require it from `gems/pancal/lib/pancal.rb`, and add it to the `READERS` list in `gems/pancal/lib/pancal/detector.rb`.
2. Implement `.allowlist_pattern` (and `.handles_url?(source)` if URL-pattern matching isn't enough) for auto-detection.
3. Implement a `#download_calendar` method that returns event data.
4. Implement an `#import_events_from(data)` method that wraps each event in your `PanCal::Events` class.

### PanCal::Events

1. Create `gems/pancal/lib/pancal/events/my_reader_event.rb`, subclassing `PanCal::Event`.
2. Implement the canonical contract: `uid`, `summary`, `description`, `location`, `dtstart`/`dtend`, `occurrences_between(from, to)`, and `publisher_url`/`online_meeting_url` where the source provides them.

Add specs (with VCR cassettes for HTTP traffic) under `gems/pancal/spec/`; the
gem suite runs standalone with `cd gems/pancal && bundle exec rspec` and also
runs in CI.
