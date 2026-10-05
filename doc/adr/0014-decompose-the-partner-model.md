# Decompose the Partner Model into Role-Based Concerns

- Author: @kimadactyl (Kim)
- Date: 2026-06-06
- Status: **Proposed (draft)**

## Context and Problem Statement

ADR 0001 (2018) combined Places and Partners into a single `Partner` model, with `is_a_place` and `can_be_assigned_events` boolean toggles standing in for what used to be separate types. That simplification was beneficial and remains load-bearing. ADR 0013 (2026) cleaned up the association naming the merge left behind (`event.partner` became `event.organiser`) and split the monolithic `EventResolver`, but it deliberately left the `Partner` model itself untouched.

The result is that `app/models/partner.rb` is now ~524 lines and carries at least five unrelated responsibility clusters in one class, gated by booleans and nullable columns:

1. **Organiser / event source**: `calendars`, `events` (both keyed on `organiser_id`), `can_be_assigned_events`, `calendar_email`/`calendar_name`/`calendar_phone`, `events_this_week`.
2. **Venue / place**: `is_a_place`, `address`, `opening_times` (+ `opening_times_data`, `human_readable_opening_times`), `accessibility_info`, `booking_info`, `matching_venue_for`, `location_name`, and the address-clearing logic (`can_clear_address?`, `warn_user_clear_address?`, `clear_address!`).
3. **Public directory listing**: contact and social fields (`public_*`, `partner_*`, `twitter_handle`, `instagram_handle`, `facebook_link`, `url`) with their format validations and URL helpers, `description`/`summary` HTML caching, the CarrierWave `image`/`logo_url`, tags/categories/facilities/partnerships, and the moderation fields (`hidden`, `hidden_reason`, `hidden_blame_id`).
4. **Geography / service areas**: `service_areas`, `service_area_neighbourhoods`, `neighbourhoods`, `owned_neighbourhood_ids`, `neighbourhood_name_for_site`, and `refresh_neighbourhood_partners_count`.
5. **Organisation graph**: the self-referential `objects`/`subjects` relationship via `organisation_relationships`, plus `managers`/`managees`.

Cutting across all of these is a sixth cluster: **neighbourhood-admin access control** (`accessed_by_user`, `check_neighbourhood_access`, `neighbourhood_admin_address_access`, `check_remove_service_area`, `partnership_admins_must_add_partnership`). This is authorization logic embedded in model validations.

A reader cannot tell, from any one method, which role it belongs to. New contributors have to hold the whole file in their head, and behaviour that only applies in one mode (for example venue-only methods) sits next to organiser-only methods with nothing separating them. This is the classic god-object that grows with every feature, and it is the next obvious piece of ADR 0001's debt to pay down now that the naming is fixed.

## Decision Drivers

- **Legibility**: a new contributor should be able to find venue logic without reading organiser logic.
- **Testability**: each role should be specifiable in isolation rather than through one large model spec.
- **Onboarding**: ADR 0013 named "new contributors struggle to understand" as a driver. The model is the next barrier.
- **De-centering Kim**: the codebase is maintained almost entirely by one person. A legible model is a precondition for a second maintainer, which is the organisational goal the whole project serves.
- **Keep ADR 0001's win**: do not re-introduce separate Place and Partner tables.
- **Follow existing convention**: `Partner` already includes `Validation`, `PartnerJsonLd`, `Permalinkable`, and `HtmlRenderCache` concerns, so role concerns extend a pattern already in use.

## Considered Options

1. **Do nothing.** Accept the 524-line model and keep adding to it.
2. **Extract role concerns, single table (recommended).** Move each cluster into a module under `app/models/partner/` (or `app/models/concerns/partner/`), included by a thin `Partner` class. No migration, no schema change.
3. **Extract role objects / POROs.** Wrap a `Partner` in `Partner::AsOrganiser`, `Partner::AsVenue`, etc., that own role logic. Stronger boundaries, but a larger change and a new calling convention across views and the import pipeline.
4. **Re-split into separate tables or STI.** Reverses ADR 0001. Rejected: it re-introduces the duplication and crude linking that 0001 was written to remove.

## Decision

Adopt **option 2**. Decompose `Partner` into role concerns, keeping the single table and single model:

- `Partner::Organiser` (events, calendars, assignable-events)
- `Partner::Venue` (address, opening times, accessibility, venue matching, address clearing)
- `Partner::DirectoryListing` (contact and social fields, descriptions, image, tags, moderation)
- `Partner::ServiceAreas` (service areas, neighbourhoods, partner-count refresh)
- `Partner::Relationships` (the organisation graph, managers/managees)

Treat the **access-control cluster separately**. The `accessed_by_user` neighbourhood-admin validations are authorization, not Partner data, and are the strongest candidate to move out of the model entirely into a policy or validator object rather than into a concern. Doing this as a follow-up step is acceptable; the point is not to bury it inside `Partner::ServiceAreas` by default.

While moving the venue cluster, fix the standing `FIXME` on `opening_times`: the field is `jsonb` but is read and written as a string (`opening_times_data`, `human_readable_opening_times` both parse it manually). The decomposition is the natural moment to store real object data and let Postgres handle it.

The end state is a thin `Partner` class that includes its role concerns and declares only what is genuinely cross-cutting.

## Consequences

### Positive

- Each role is findable and specifiable on its own; the model spec can be split to match.
- `Partner` shrinks to an aggregator, lowering the barrier to a second maintainer.
- Establishes a reusable pattern for the other oversized models (`site.rb` and `calendar.rb` are both ~327 lines).
- Forces the `opening_times` jsonb cleanup that has carried a `FIXME` for years.

### Negative

- **Concerns organise, they do not enforce.** Everything still shares one table and one object, so this is a readability gain, not true decoupling. Without discipline it can become "include-driven development" that hides coupling rather than removing it.
- **Some methods genuinely span roles.** `owned_neighbourhood_ids` and `location_name` read both `address` (venue) and `service_areas` (geography), so the boundaries will not be perfectly clean and some judgement calls are unavoidable.
- It is internal refactoring with no user-facing output, competing for time with paid productisation work. It is best triggered by onboarding a contributor rather than done speculatively.

## References

- [ADR 0001: Combine Places and Partners](0001-combine-places-and-partners.md)
- [ADR 0013: Clarify Event Organiser and Place Associations](0013-clarify-event-organiser-and-place-associations.md)
- `app/models/partner.rb` (the model under discussion)
