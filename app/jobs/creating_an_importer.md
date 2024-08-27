# How the importer works

Calendars can be imported through the following rake tasks:

```
rails events:import_all_calendars # Imports all calendars - usually in dev environment
rails events:import_calendars[:id] # Imports one calendar - usually in a dev environment
rails events:scan_for_calendars_needing_import # Imports only updated calendars - run as a cronjob
```

They can also be triggered in the Calendar interface in the web admin.

All of these tasks create `CalendarImporterJob`s (/app/jobs/calendar_importer_job.rb). This job is how all external URLs get turned into Events and imported into PlaceCal, with Calendars being effectively the configuration for how to import them.

1. `CalendarImporterJob` looks up each Calendar. It creates a...
2. `CalendarImporter::CalendarImporterTask`, which identifies the calendar type and attempts to load it using a...
3. `CalendarImporter::Parsers::MyParser`, which queries a URL and sends the data from it to...
4. `CalendarImporter::EventResolver`, which analyses event data and creates one or more...
5. `CalendarImporter::Events::MyParser`, which attempts to load an event into PlaceCal

## Adding a new importer

Importers require two parts:

1. A **CalendarImporter::Parsers**, which reads a remote URL and turns it into something Rails can work with
2. A **CalendarImporter::Events**, which takes the data and creates one or more Events inside PlaceCal.

### CalendarImporter::Parsers

1. Create `/app/jobs/calendar_importer/parsers/my_parser.rb` and link it from `/app/jobs/calendar_importer/calendar_importer.rb`.
2. Implement a `#download_calendar` method that returns event data.
3. Implement an `#import_events_from(data)` method that invokes a `CalendarImporter::Events`.

### CalendarImporter::Events

1. Create `/app/jobs/calendar_importer/events/my_parser.rb`.
2. Add methods to map your retrieved events onto PlaceCal Events model (nb: we should define this more clearly)
