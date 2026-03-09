# Calendar Import Pipeline

This document describes how PlaceCal imports events from external calendar sources.

## Pipeline Overview

```
CalendarImporterJob
  → CalendarImporter::CalendarImporter (detects parser)
    → Parser (ICS, Eventbrite, TicketSource, etc.)
      → CalendarImporter::Events::* (normalised event data)
        → CalendarImporter::EventResolver (coordinator)
          → CalendarImporter::LocationResolver (place + address)
          → CalendarImporter::OnlineDetector (online links)
          → save_all_occurences (persist to DB)
```

## Key Concepts

### Organiser vs Place vs Address

- **Organiser** (`event.organiser`): The Partner running the event. Set from `calendar.organiser`.
- **Place** (`event.place`): The Partner whose venue hosts the event. May be the same as organiser, or different (e.g., "Book Club" runs events at "Central Library").
- **Address** (`event.address`): The physical location. Can come from the event data, the place, or the organiser (fallback).
- **Online Address** (`event.online_address`): A URL for virtual attendance (Zoom, Google Meet, Jitsi, etc.).

### Address Resolution Order

When displaying an event's location, the system checks in order:

1. Event's own address (`event.address`)
2. Place's address (`event.partner_at_location.address`)
3. Organiser's address (`event.organiser.address`)

## Location Strategies

Each Calendar has a `strategy` that determines how imported events get their place and address.

| Strategy         | Place                               | Address                             | Use When                                 |
| ---------------- | ----------------------------------- | ----------------------------------- | ---------------------------------------- |
| `place`          | Calendar's default place            | Place's address                     | All events at one venue                  |
| `event_override` | Calendar's default place (fallback) | From event data, or place's address | Most events at one venue, some elsewhere |
| `event`          | None                                | Parsed from event location field    | Events at varying locations              |
| `room_number`    | Calendar's default place            | Place's address + room from event   | One venue, different rooms               |
| `no_location`    | None                                | None                                | Events without physical location         |
| `online_only`    | None                                | None                                | Purely online events                     |

## Online Detection

`OnlineDetector` checks event data for online meeting links:

- Google Meet custom properties (`x_google_conference`)
- URLs in description matching: Zoom, Google Meet, Jitsi, Microsoft Teams
- Eventbrite's `online_event` flag

## Parsers

| Parser       | Source                | API Key? | Notes                                  |
| ------------ | --------------------- | -------- | -------------------------------------- |
| ICS          | `.ics` feeds          | No       | Google Calendar, Outlook, generic iCal |
| Eventbrite   | `eventbrite.co.uk/o/` | No       | Scrapes organiser pages                |
| TicketSource | `ticketsource.co.uk`  | Yes      | Uses REST API with Basic Auth          |
| TicketTailor | `tickettailor.com`    | Yes      | Uses REST API                          |
| Outsavvy     | `outsavvy.com`        | No       | Scrapes event pages                    |
| LdJson       | Any URL with JSON-LD  | No       | Downloads page, parses LD+JSON schema  |

### Parser Detection

`CalendarImporter::CalendarImporter` auto-detects the parser by:

1. Checking if any parser's `handles_url?` matches the source URL
2. If `importer_mode` is set to a specific parser key, uses that directly
3. Falls back to ICS if the URL returns valid iCal data

API-based parsers (TicketSource, TicketTailor) extend `ApiBase` and use `skip_source_validation?` to skip HTTP source checks during calendar creation.

## Event Deduplication

Events are identified by `(calendar_id, uid, dtstart, dtend)` with a unique database index. On re-import:

- Existing events with matching UIDs are updated in place
- For recurring events, occurrences with changed times are removed
- `RecordNotUnique` exceptions are caught and handled gracefully
