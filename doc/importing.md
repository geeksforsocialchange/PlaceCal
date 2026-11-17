# Calendar Import Pipeline

This document describes how PlaceCal imports events from external calendar sources.

## Pipeline Overview

```
RecurringCalendarScanJob (hourly)
  → CalendarImporterJob
    → CalendarImporter::CalendarImporterTask
      → CalendarImporter::CalendarImporter (validates the source, picks the parser)
      → Parser (download, checksum, parse)
        → CalendarImporter::Events::* (one per source event)
      → CalendarImporter::EventResolver (one per event)
        → resolve: online link, then LocationResolver (place + address), then organiser
        → save_all_occurrences: OccurrenceSync (persist to DB)
```

[RecurringCalendarScanJob](../app/jobs/recurring_calendar_scan_job.rb), run hourly by Solid Queue from [config/recurring.yml](../config/recurring.yml), resets stuck imports, then queues every calendar that is not already queued or importing. Creating a calendar also queues it. In [CalendarImporterJob](../app/jobs/calendar_importer_job.rb), an unreachable source puts the calendar in `bad_source` and other failures put it in `error`; neither is retried, since the next hourly scan queues the calendar again. An import is stopped after 20 minutes. Root users see calendars with problems and imports in progress at `/jobs` on the admin site; job errors go to AppSignal.

[CalendarImporterTask](../app/jobs/calendar_importer/calendar_importer_task.rb) runs one import:

- A feed whose checksum matches the last import is not parsed, unless the import is forced. Editing the source, importer or API key clears the checksum.
- Private events are skipped: iCal `CLASS:PRIVATE`, or `#placecal-ignore` in the description.
- Occurrences run from the import date to a year ahead, capped at 1,000 per event and 20,000 per calendar. Each cap adds a notice.
- After a parsed feed, upcoming events whose UID was not imported this run are deleted, unless the calendar cap was reached.
- An empty feed keeps its upcoming events for 48 hours, then deletes them.
- Locations that can't be read as an address give one notice per reason.
- If Eventbrite still fails after retries, the import is skipped and existing events stay.

## Key Concepts

### Organiser vs Place vs Address

- **Organiser** (`event.organiser`): The Partner running the event. Set from `calendar.organiser`.
- **Place** (`event.place`): The Partner whose venue hosts the event. May be the same as organiser, or different (e.g., "Book Club" runs events at "Central Library").
- **Address** (`event.address`): The physical location, set by the location strategy.
- **Online Address** (`event.online_address`): A URL for virtual attendance.

### Source Categories and Organiser

Each event keeps, as plain text, the categories and organiser name its source gives: iCal `CATEGORIES` and the `CN` of `ORGANIZER`, JSON-LD `keywords` and the `organizer` name, and Squarespace `categories` and `tags`, in `source_categories` and `source_organiser`. They don't create or link PlaceCal categories or partners. Other sources give neither.

An event stores one image, downloaded from its source into `event.image` (`EventImageUploader`) when the source's URL for it, kept in `image_source_url`, changes. Eventbrite (`logo.original.url`), Ticket Tailor (`images.header`), Squarespace (`assetUrl`), JSON-LD (`image`) and iCal (`IMAGE`, or the first `ATTACH` that is an image; Google Drive links are fetched in their download form, which works when the file is shared publicly) give one. A download that fails leaves the event without an image and is retried on the next import that reads it. A file that isn't a JPEG, PNG, GIF or WebP image leaves it without one until the source's URL changes.

### Address Resolution Order

[Event#resolved_address](../app/models/event.rb) uses the first of:

1. The event's own address.
2. The place's address, when the place is not hidden. A place with no address gives no address, not the organiser's.
3. The organiser's address, when there is no place or the place is hidden.

## Location Strategies

Each Calendar has a `strategy` that sets how imported events get their place and address, in [location_resolver.rb](../app/jobs/calendar_importer/location_resolver.rb).

| Strategy                     | Place and address                                                                                                                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `event`                      | The event's location as an address, with a partner at that address as the place. No location: the default place (if set) and no address.                                                   |
| `event_override`             | The event's location as an address, with a partner at that address as the place. If no partner matches but it is the default place's building: as `place`. No usable location: as `place`. |
| `place`                      | The default place and its address.                                                                                                                                                         |
| `room_number`                | The default place, with the event's location added as the first line of a copy of its address. Needs a default place.                                                                      |
| `no_location`, `online_only` | No place and no address.                                                                                                                                                                   |

Location text becomes an address only with a street line and a full UK postcode that passes validation. When the default place has no address, `place`, `event_override` and `room_number` import events at that place with no address. An event that fails validation is skipped and recorded as an import notice.

## Online Detection

Each event class's `online_event_id` decides whether an event is online, for every strategy. `EventResolver#resolve` calls it before resolving the location, so its `OnlineAddress` is created even when the location raises a `Problem` and the event isn't saved.

- **iCal** ([ics_event.rb](../app/jobs/calendar_importer/events/ics_event.rb), also used by Meetup) checks, in order: the custom properties in `ONLINE_MEETING_PROPERTIES` (Google, Microsoft Teams and Zoom meeting links), a LOCATION that is a link to a meeting host, then the first meeting link in the description. Meeting hosts are the `:meeting` services in `OnlineAddress::SERVICES` ([online_address.rb](../app/models/online_address.rb)), such as Zoom, Google Meet, Jitsi and Microsoft Teams. These links are stored as `direct`.
- **Eventbrite** ([eventbrite_event.rb](../app/jobs/calendar_importer/events/eventbrite_event.rb)) uses the `online_event` flag and links to the Eventbrite page as `indirect`.

Other sources are never marked online.

Links to stream and social hosts (YouTube, Facebook, Instagram, LinkedIn and the like) don't mark an event online. A LOCATION that is a link to anything but a meeting host is the event's webpage link when it has no URL property.

## Parsers

`PARSERS` in [calendar_importer.rb](../app/jobs/calendar_importer/calendar_importer.rb), in detection order:

| Parser                | Source URL                                                                | Reads                                                       |
| --------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Eventbrite            | `eventbrite.com/o/…`, `eventbrite.co.uk/o/…`                              | The Eventbrite API, with the server-wide `EVENTBRITE_TOKEN` |
| Generic iCal / .ics   | Google Calendar, Outlook, Teamup, `webcal://`, `*.ics`, a few named sites | The iCal feed                                               |
| TicketSource          | `ticketsource.co.uk/<venue>`, `ticketsource.com/<venue>`                  | The TicketSource API, with the calendar's API key           |
| Manchester University | `events.manchester.ac.uk/f3vf/calendar/…`                                 | The XML feed (hidden from the admin importer list)          |
| Meetup                | `meetup.com/<group>`                                                      | The group's iCal feed                                       |
| OutSavvy              | `outsavvy.com/organiser/<name>`                                           | Each event page's LD+JSON, found from the organiser page    |
| Resident Advisor      | `ra.co/promoters/<id>`, `ra.co/clubs/<id>`                                | The ra.co GraphQL API                                       |
| Squarespace           | `*.squarespace.com`, or a custom domain detected as Squarespace           | The page's `?format=json` data                              |
| Ticket Solve          | `*.ticketsolve.com`                                                       | The XML feed                                                |
| Ticket Tailor         | `tickettailor.com/events/<box office>`                                    | The Ticket Tailor API, with the calendar's API key          |
| Wix Events            | `*.wixsite.com`, or a custom domain detected as Wix                       | Event JSON embedded in the page                             |
| LD+JSON               | Any page                                                                  | Schema.org events in the page's LD+JSON                     |

### Parser Detection

[CalendarImporter::CalendarImporter](../app/jobs/calendar_importer/calendar_importer.rb) picks the parser when a calendar's source is saved and at each import:

1. A URL matching a parser whose `skips_source_check?` is true (TicketSource, Ticket Tailor, Resident Advisor) uses that parser, without fetching the page.
2. Otherwise the URL is fetched, and an error status fails the check.
3. A set `importer_mode` picks the parser with that key. The legacy modes `out-savvy` and `dice-fm` map to LD+JSON.
4. With `importer_mode` blank or `auto`, the first parser in `PARSERS` whose `handles_url?` matches is used. Squarespace and Wix also fetch the page to detect custom domains. LD+JSON is last because it downloads and parses the page.
5. If nothing matches, the feed is unsupported. There is no fallback to iCal.

## Source URL Restrictions

Every fetch through `CalendarImporter::Parsers::Base.read_http_source` goes through `OutboundUrlGuard` ([outbound_url_guard.rb](../app/services/outbound_url_guard.rb)). It stops an admin pointing the server at internal services (SSRF). Requests to the TicketSource, Ticket Tailor, Eventbrite and Resident Advisor APIs go to fixed hosts and do not use it.

The guard resolves the hostname and refuses the URL if any address is loopback, private, link-local or otherwise internal. Redirects are checked hop by hop. A refused URL raises `InaccessibleFeed` with the `admin.calendars.wizard.source.private_address` message.

This applies in every environment, so these sources are refused in development too:

- `http://localhost:3000/...`, `http://lvh.me:3000/...` and `http://127.0.0.1/...`
- Anything on a private network, such as `http://192.168.1.10/feed.ics` or a hostname that only resolves on a VPN

To test an importer against a local file, record a VCR cassette or stub the request in a spec instead of serving the feed from your machine. To try a feed by hand in development, host it somewhere with a public address.

In specs, `spec/support/outbound_url_guard.rb` stubs `OutboundUrlGuard.resolve` so hostnames resolve to a public documentation address and no real DNS lookup happens. Override that stub in a spec to simulate a hostname that resolves privately.

Remote JSON-LD `@context` documents are only loaded from schema.org. Any other remote context is refused.

## Event Deduplication

Events are identified by `(calendar_id, uid, dtstart, dtend)` with a unique database index. On re-import, [EventResolver](../app/jobs/calendar_importer/event_resolver.rb):

- Updates the existing row for each occurrence, matched by UID and times. A one-off event reuses its row, so a rescheduled event keeps its id.
- Deletes rows for the UID from the import date on that match no current occurrence. Earlier rows are kept.
- Catches `ActiveRecord::RecordNotUnique` and updates the matching row.
