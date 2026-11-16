# Importer Rework: Locations, Venues, Online Events, Import Runs and Rules

- Author: @kimadactyl (Kim)
- Date: 2026-11-16
- Status: **Proposed**

## Context and Problem Statement

The calendar importer turns a partner's feed into events. Partners find it clunky, and four problems explain most of that:

1. **Location is tangled.** One six-way "location strategy" setting answers several questions at once, and a calendar's default location can only be a partner the user manages. A venue run by someone else, or not on PlaceCal, can't be picked. Partners based in someone else's building copy its address, and the copy drifts.
2. **Imports are invisible.** A run records no counts and no per-event outcome, its notices are cleared within the hour, and the status only changes on reload.
3. **"Online" is a guess.** PlaceCal stores whether an event has a link attached, not whether it is online. In-person events with a social media or ticket link show as online, and most sources never detect online events at all.
4. **Sources offer more than we take.** Images, ticket links, prices, cancellations and categories are in the feeds and dropped. What each source reads is written down only in code.

Separately, every event gets its calendar's organiser and a feed can only be added once, so one feed can't be split between organisers.

## Decision Drivers

- Partners without technical knowledge set calendars up, so each setting answers one plain question.
- Admins can see what an import did.
- An address lives in one place.
- One place says what each source reads.

## Decision

1. **One location rule.** If an event has its own valid address, use it. Otherwise use the calendar's default location. With neither, the event has no location. The default location is optional, and a checkbox says "the location field shows a room number". This replaces the location strategy setting.
2. **Any venue can be a default location.** One search offers partners with "Event Matching" switched on, and venues not on PlaceCal from an external venue search, with manual address entry as the fallback. A venue not on PlaceCal is saved once as a shared record that later calendars reuse, and it can be turned into a partner.
3. **Partners say where they are based:** their own premises, another venue (its address read live, never copied), or a service area.
4. **Events store their attendance:** in person, online, or both. Each calendar answers "Are events on this calendar online?" with Never, Sometimes or Always, starting on Sometimes. Under Sometimes, only the feed's own flag or a link to a meeting service counts. One detector serves every source.
5. **Each import run is recorded,** with its outcome, counts and what happened to each event. A results page shows it and replaces the notices list. The calendar's status updates by polling.
6. **Each source declares the fields it reads,** and the in-app and handbook tables are generated from that. New fields are then added one at a time: image, cancelled status, ticket details.
7. **A calendar can have ordered rules** that skip matching events or give them to another partner. Anyone who can edit the calendar can give events to any partner, and that partner's users are emailed.

## Options Not Taken

- **More strategy values:** multiplies a list that is already hard to explain.
- **A typed address per calendar:** repeats the drift on every calendar using the same hall.
- **Tighter link-based online detection alone:** can't tell an auto-attached meeting link from a real one, or express "both".
- **Pushed live updates:** need a cable backend that isn't deployed. Polling needs nothing new.
- **The same feed on two calendars:** fetches twice and hides from the venue where its events went.
- **A hand-maintained source table:** drifts from the code.

## Consequences

- The calendar form asks a few plain questions instead of one six-way choice.
- Behaviour changes on purpose: calendars that ignore event addresses today will show an event at its own address when it has a valid one. The events this moves are counted and reviewed before migrating.
- Existing calendars and events need a data migration to the new settings and to stored attendance.
- Other people's events can appear on a venue's page. "Event Matching" is the venue's control over that.
- The venue search is a new outside dependency with its own terms and attribution.

## Order of Work

1. Tidy and fix
2. Import runs, results page and live status
3. Declared field maps, then new fields
4. Online events
5. Location
6. Rules

The results page comes before the stages that change what happens to events, so their effect can be checked. The work is tracked in the [Importer rework milestone](https://github.com/geeksforsocialchange/PlaceCal/milestone/56).

## Open Questions

- Is the email to a partner receiving events a notification, or a confirmation the rule waits for?

## References

- [ADR 0013: Clarify Event Organiser and Place Associations](0013-clarify-event-organiser-and-place-associations.md)
- `doc/importing.md`: the current import pipeline
