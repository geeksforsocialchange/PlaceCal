# Importer Rework: Locations, Venues, Online Events, Import Runs and Rules

- Author: @kimadactyl (Kim)
- Date: 2026-11-16
- Status: **Proposed**

## Context and Problem Statement

The calendar importer turns a partner's feed into events. ADR 0013 split its event handling into `LocationResolver`, `OnlineDetector` and `EventResolver`, and settled that an event has an organiser and a place. Partners find it clunky: the form's options are tangled, nothing shows what an import did, a calendar can't use a venue the partner doesn't manage, and one feed can't be shared between organisers. Four problems explain most of this.

**1. Location is tangled.** `Calendar#strategy` (`app/models/calendar.rb:74`) has six values (`place`, `event_override`, `event`, `room_number`, `no_location`, `online_only`), each a mix of separate answers: is there a default location, is the event's own location read, and is it an address or a room. The default location must be a `Partner`, and the picker (`options_for_location`, `app/helpers/calendars_helper.rb:8`, used by `app/views/admin/calendars/form_tab_location.rb` and `new.rb`) offers only partners in the user's policy scope that have an address. `CalendarPolicy#partners_in_scope?` (`app/policies/calendar_policy.rb:37`) enforces the same scope on save. A venue on PlaceCal that the user doesn't manage can't be picked, and a venue not on PlaceCal has nowhere to go. Partners based in someone else's building type its address in as their own, and the copy drifts ([#2522](https://github.com/geeksforsocialchange/PlaceCal/issues/2522)).

**2. Imports are invisible.** A calendar keeps its state, last import time, importer used, any critical error and a list of notices. The only other trace is a two-week activity log of event changes (`Calendar#recent_activity`). There are no per-run counts, no history of runs and no record of how each event's location resolved. The notices are wiped within an hour: `Calendar#queue_for_import!` sets `notices: nil` (`calendar.rb:249`), `RecurringCalendarScanJob` queues every calendar hourly, and an unchanged feed writes back an empty list (`app/jobs/calendar_importer/calendar_importer_task.rb:35`). The status strip (`app/views/admin/calendars/importer_overview.rb`) only changes on reload. An address that can't be built is dropped with no notice (`Address.build_from_components`, `app/models/address.rb:80`). Changing a calendar's source clears its status but `Admin::CalendarsController#update` queues no import, so the new feed waits for the hourly scan.

**3. "Online" is a guess.** PlaceCal stores no attendance mode. The public site treats an event as online when it has an online address (`app/components/sites/event.rb:227`). Only `IcsEvent` (also used by Meetup, whose parser subclasses `Ics`) and `EventbriteEvent` attach one; every other class in `app/jobs/calendar_importer/events/` inherits `online_event_id` returning nil from `Base`. For iCal, any web address in the location field counts, and so does a description link to any domain in `OnlineAddress::SERVICES`, which includes Facebook, Instagram, LinkedIn and YouTube (`ics_event.rb:97`). An in-person event linking to the organiser's Instagram is shown as online ([#2512](https://github.com/geeksforsocialchange/PlaceCal/issues/2512)). Calendar apps such as Google and Outlook can attach meeting links automatically, and nothing can tell those from real ones. For Eventbrite the online link is the event's own page (`eventbrite_event.rb:74`), already stored as its webpage. An `online_only` calendar discards locations but marks nothing online, and there is no way to say an event is both at a venue and online. In the code, `OnlineDetector` is a one-line pass-through, the iCal class creates `OnlineAddress` rows while parsing, and known services are recognised twice (by hostname in `OnlineAddress.service_for`, by substring in `IcsEvent#link_type_for`).

**4. Sources offer more than we take.** An imported event stores title, description, times, repeat rule, raw location, place, address, organiser, one webpage link and an online address (`Events::Base#attributes`), plus a "spaces available" value only Ticketsolve fills (`event_resolver.rb:63`). `LinkedDataEvent` reads event status to skip cancelled and postponed events, but not attendance mode, image, organiser or offers. `TickettailorEvent#location` reads only venue name and postcode. Ticketsolve's ticket link is built as a footer, appended to the description only when the description is HTML, and never saved to `events.footer`. Recorded feeds and published formats show images, ticket links, prices, availability, categories, organisers and coordinates going unused. What each source reads is written down only in the code of eleven event classes ([#1948](https://github.com/geeksforsocialchange/PlaceCal/issues/1948)).

Separately, every event gets the calendar's organiser (`event_resolver.rb:46`), and `calendars.source` is unique (`db/schema.rb:92`), so one feed can't be split between organisers. The only filters are `#placecal-ignore` in a description and an iCal class of private (`events/base.rb:132`).

## Decision Drivers

- **Partners without technical knowledge set calendars up,** so each setting answers one plain question.
- **Admins must see what an import did,** per run and per event.
- **No drift between copies of the same address.**
- **One place says what each source reads.**
- **Changes must be checkable on real feeds before and after.**

## Considered Options

- **Location settings.** Keeping the strategy enum and adding values multiplies a list that is already hard to explain. _Chosen:_ one rule plus an optional default location, which separates the questions the enum mixes.
- **Venues not managed by the user, or not on PlaceCal.** A typed address per calendar is quick but repeats the drift of #2522 on every calendar using the same hall. _Chosen:_ a shared venue record, saved once, picked by later calendars, countable, and convertible into a partner.
- **Online events.** Inferring online from links, even with tighter rules, can't tell an auto-attached link from a real one or express "both". _Chosen:_ stored attendance per event plus a per-calendar question with Never, Sometimes and Always, because the partner is the one who knows.
- **Live status.** Pushed updates need a cable backend first: `config/cable.yml` names Redis, but the `redis` gem is not in `Gemfile.lock` and the Kamal deploy configs don't mention it. _Chosen:_ polling, with no new infrastructure. Revisit only if it feels slow.
- **One feed, several organisers.** Allowing the same feed on two calendars drops the unique index, fetches twice, and hides from the venue where its events went. _Chosen:_ ordered rules on one calendar.
- **What each source reads.** A hand-maintained handbook table drifts from the code. _Chosen:_ field maps declared in the event classes, rendering both the in-app table and the handbook table.

## Decision

### 1. One location rule and an optional default location

The `strategy` setting is replaced by:

- **One rule:** if an event has its own valid address, use it; otherwise use the default location; with neither, no location. An event at its own address never carries the default venue's name.
- **Default location:** optional, a partner or a shared venue (decision 2).
- **"The location field shows a room number":** a checkbox, once a default location is set. Each event's location text is shown as a room at the default location and never read as an address.

There is no "ignore the feed's locations" option. Existing calendars carry over like this:

| Strategy today            | Default location                    | Room number box | Online question |
| ------------------------- | ----------------------------------- | --------------- | --------------- |
| `place`, `event_override` | kept                                | off             | Sometimes       |
| `room_number`             | kept                                | on              | Sometimes       |
| `event`                   | kept if one is set, otherwise blank | off             | Sometimes       |
| `no_location`             | blank                               | n/a             | Sometimes       |
| `online_only`             | blank                               | n/a             | Always          |

### 2. Shared venue records, found with one search

The default location becomes one search with two kinds of result:

- **A partner,** from across PlaceCal. The event links to it and follows its address. Only partners with "Event Matching" (`can_be_assigned_events`) switched on are offered, the switch `Partner.matching_venue_for` already requires (`app/models/partner.rb:249`).
- **A venue not on PlaceCal,** from a venue search service, with "Can't find it? Enter an address" as the fallback. It is saved once as a shared record (name, address, external ID). Events show its name and address with no partner link. Counting calendars and events per record shows the most used venues, and a busy one can become a partner with its calendars attached.

OpenStreetMap is the proposed source: open, and good on community venues. Its main public search server does not allow search-as-you-type, so a hosted service or a self-run Photon instance is needed. Overture Maps and Foursquare Open Source Places suit a bulk load; Ordnance Survey and Google Places are paid and restrict storage. These points need checking before work starts. The first step is a read-only report from PlaceCal's own events of the most used venues not on PlaceCal.

### 3. Partners say where they are based

The partner form asks one question: "We have our own premises" (an address), "We're based at another venue" (picked with the decision 2 search, its address read live, never copied), or "We work across an area" (service areas). This removes the drift in #2522 and lets a venue's page list who is based there.

### 4. Stored attendance and the online question

- **Each event stores its attendance:** in person, online, or both. A venue plus a meeting link is both.
- **Each calendar answers "Are events on this calendar online?"** _Never:_ meeting links are ignored. _Sometimes:_ online only when the feed says so (an attendance flag, or iCal conferencing properties) or a link goes to a meeting service such as Zoom, Meet, Teams or Jitsi; social media links and unknown web addresses never count, and a web address in the location field becomes the webpage link. _Always:_ every event is online.
- **One detector for every source,** in `OnlineDetector`, which returns an answer and writes nothing.

### 5. Import runs and live status

- **A record of each run:** outcome, counts (added, changed, removed, skipped), and per event what was read and how its location resolved. A results page shows it, and it replaces the notices list. It also supplies [#3664](https://github.com/geeksforsocialchange/PlaceCal/issues/3664), [#2026](https://github.com/geeksforsocialchange/PlaceCal/issues/2026) and [#3769](https://github.com/geeksforsocialchange/PlaceCal/issues/3769).
- **Live status by polling** on the status strip while a calendar is queued or importing.

### 6. Declared field maps, then the unused fields

Each event class declares which source field fills which PlaceCal field; the admin source table and the handbook table are generated from that (#1948). New fields then land one at a time: image ([#3728](https://github.com/geeksforsocialchange/PlaceCal/issues/3728)), cancelled and postponed status ([#3801](https://github.com/geeksforsocialchange/PlaceCal/issues/3801)), then a ticket block (a "Book tickets" link, price, sold out). Categories and source organiser come with decision 7, coordinates with the location work.

### 7. Rules on a calendar

A calendar can have an ordered list of rules: when the title, description, location, category or source organiser contains some text, skip the event or give it to a named partner. This splits a shared feed and covers hiding "private hire" events ([#1585](https://github.com/geeksforsocialchange/PlaceCal/issues/1585)). Where a feed carries categories or names its organiser, rules match on those. The same feed on two calendars stays disallowed.

### The calendar form

Source and organiser as now; an optional default location; the room number checkbox; "Are events on this calendar online?"; an optional default description ([#1930](https://github.com/geeksforsocialchange/PlaceCal/issues/1930)); optional rules.

## Consequences

### Positive

- The form asks a few plain questions instead of one six-way choice.
- Partners can use any venue that accepts events, and venues not on PlaceCal, without copying addresses.
- Admins can see what each run did and check later changes against it.
- In-person events stop being shown as online, and feeds that state attendance are believed.
- One declaration documents what each source reads, in the app and the handbook.

### Negative

- **Behaviour changes on purpose.** `place` and `no_location` calendars ignore event addresses today; afterwards an event with its own valid address shows there. The number of live events this moves is counted and reviewed before migrating. `online_only` calendars start marking every event online.
- **Data migration** from strategies to the new settings, and from online addresses to stored attendance.
- **Other people's events appear on a venue's page** once anyone can pick it. "Event Matching" limits this, but it defaults to on.
- **A new dependency on a venue search service,** with its own terms, limits and attribution, or a search server to run.

## Order of Work

1. **Tidy and fix:** the default venue name shown on events at their own address (`location_resolver.rb:53`), queueing an import on source change, a notice for unbuildable addresses, a feed that empties keeping its old events (`calendar_importer_task.rb:19`), wizard errors, dead code, `doc/importing.md`. Safe, and makes the rest easier to read.
2. **Import runs, results page, live status.** Stages 4 to 6 change what happens to events, and without a results page there is no way to see whether they did the right thing.
3. **Field maps, then new fields,** so each field shows in the table as it lands.
4. **Online events.** Smaller than location, fixes something visibly wrong on public pages, and location needs attendance to be stored.
5. **Location** (decisions 1 to 3), with [#1512](https://github.com/geeksforsocialchange/PlaceCal/issues/1512) and [#2254](https://github.com/geeksforsocialchange/PlaceCal/issues/2254). The largest stage, with the most product decisions.
6. **Rules.**

## Open Questions

These are **open**.

- **Notices wipe:** patch it now, or leave it for stage 2 to replace?
- **New calendars:** does the online question start on "Sometimes", or have no default so the person must choose?
- **Other people's venues:** is "Event Matching" the right gate for which partners can be a default location?
- **Rules:** who may give events to a partner they don't manage?

## References

- [ADR 0013: Clarify Event Organiser and Place Associations](0013-clarify-event-organiser-and-place-associations.md)
- Issues: [#2522](https://github.com/geeksforsocialchange/PlaceCal/issues/2522), [#2512](https://github.com/geeksforsocialchange/PlaceCal/issues/2512), [#3664](https://github.com/geeksforsocialchange/PlaceCal/issues/3664), [#2026](https://github.com/geeksforsocialchange/PlaceCal/issues/2026), [#3769](https://github.com/geeksforsocialchange/PlaceCal/issues/3769), [#1948](https://github.com/geeksforsocialchange/PlaceCal/issues/1948), [#3728](https://github.com/geeksforsocialchange/PlaceCal/issues/3728), [#3801](https://github.com/geeksforsocialchange/PlaceCal/issues/3801), [#1512](https://github.com/geeksforsocialchange/PlaceCal/issues/1512), [#2254](https://github.com/geeksforsocialchange/PlaceCal/issues/2254), [#1930](https://github.com/geeksforsocialchange/PlaceCal/issues/1930), [#1585](https://github.com/geeksforsocialchange/PlaceCal/issues/1585)
- Related: [#2854](https://github.com/geeksforsocialchange/PlaceCal/issues/2854) (importer as a gem) and [#3307](https://github.com/geeksforsocialchange/PlaceCal/issues/3307) (feed health check)
- `doc/importing.md`: the current import pipeline
