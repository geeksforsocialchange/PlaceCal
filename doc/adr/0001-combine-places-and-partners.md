# Combine Places and Partners

- Deciders: kimadactl, gabagrant
- Date: 2018-05-28

## Context and Problem Statement

Partners and Places both contain a lot of shared functionality. They can also only currently be linked in very crude ways (Partners manage Places), which is resulting in some on-the-ground situations not being mappable into PlaceCal. This would roll both into one model with a variety of toggleable functionality. We need to find a way to simplify and improve the possibilities of relationships between Places, Partners and the rest of the site.

## Decision Drivers

- Places and Partners are not intuitive units and duplicate a lot of functionality.
- It's desirable to have multiple different relationship types between real-life assets such as multiple people managing one place.
- There's a lot of duplicated code that can be removed, adding to maintainability.

## Considered Options

- Migrate to having one type, Partners, that have Place functionality as a toggle. Relationships are all partner to partner.
- Keep the system as it is by adding many relationship types between Partners and Places. Risks creating even more duplication of functionality.

## Decision Outcome

Chosen option 1.

Positive Consequences:

- Less code, making it easier to maintain
- A single relationship table will make for clearer and more deterministic relationships
- Allows more complex relationships between multiple partners.
- Events can be owned by multiple partners

Negative consequences:

- A lot of work to clean up messy forms and re-do relationships
- Could be difficult to decide what is shown on each partner's page
- Multiple relationship types can make permissions messy

## Work to do

- Parters currently have the most functionality, so use as base type.
- Migrate all Places to Partners, and delete.
- Add is_a_partner boolean to show that they should show up on the frontend
- is_a_place boolean now indicates if open to the public
- Create Partner relationship table with options (see below)
- Update Addresses, Calendars, Sites and Turfs to only link to Partners
- Update frontend to only have Partners
- Events can belong to organiser Partners and venue Partners

### Partner Relationships

Calendar examples

- Calendars are assigned to Partners
- Events can assign themselves to an extra Partner with the Location field on address match.

View examples

- Big Life Centres [manages] Zion and Kath Locke Centre. Shows events from both.
- Zion Centre [is managed by] Big Life Centres. Shows Zion events and links to Big Life.
- Trinity House [hosts] Link Good Neighbours. Shows events from both.
- Link Good Neighbours [is based at] Trinity House. Show Link Good Neighbours events.
