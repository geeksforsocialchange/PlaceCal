# Clarify Event Organiser and Place Associations

- Author: @kimadactyl (Kim)
- Date: 2026-03-09
- Status: **In progress**

## Context and Problem Statement

Events have two associations pointing to the Partner model: `partner` (the organiser running the event) and `place` (the venue hosting the event). The naming `event.partner` for "organiser" is confusing — readers can't tell if it means the organisation running the event or the venue hosting it. The frontend also doesn't clearly show both organiser and venue to users.

This was a consequence of ADR 0001 which combined Places and Partners into a single model. While that simplification was beneficial, it left the naming ambiguous.

## Decision Drivers

- Code clarity: `event.partner` is ambiguous — could mean organiser or venue
- Frontend gaps: event listings only show location, not "By X at Y"
- Event show page doesn't clearly distinguish organiser from venue
- EventResolver handles too many responsibilities (location, online detection, saving)
- New contributors struggle to understand the import pipeline

## Decision

### Rename associations

- `event.partner` → `event.organiser` (with `class_name: 'Partner'`)
- `calendar.partner` → `calendar.organiser` (with `class_name: 'Partner'`)
- Keep `event.place` and `calendar.place` as-is (already clear)

### Rename database columns

- `events.partner_id` → `events.organiser_id`
- `calendars.partner_id` → `calendars.organiser_id`

### Rename scopes

- `Event.by_partner` → `Event.by_organiser`
- `Event.by_partner_or_place` → `Event.by_organiser_or_place`

### Split EventResolver

Break the monolithic EventResolver into focused pieces:

- `CalendarImporter::LocationResolver` — determines place and address from calendar strategy
- `CalendarImporter::OnlineDetector` — determines online_address from event data
- `CalendarImporter::EventResolver` — remains as coordinator, calling the above two

### Improve frontend display

- Event listing: show "By [Organiser] at [Place]" instead of just location
- Event show page: show venue section when place differs from organiser

### Document import pipeline

Add `doc/importing.md` explaining the full import flow and how organiser, place, address, and online_address relate.

## Consequences

### Positive

- Association names are self-documenting
- Frontend clearly shows who runs an event vs where it happens
- EventResolver has single responsibility
- Import pipeline is documented for new contributors

### Negative

- Large rename across ~50 files (migration, models, views, specs, factories)
- GraphQL API internally changes but `organizer` field name stays the same (no breaking API change)

## References

- [ADR 0001: Combine Places and Partners](0001-combine-places-and-partners.md)
- [Issue #2917](https://github.com/geeksforsocialchange/PlaceCal/issues/2917)
