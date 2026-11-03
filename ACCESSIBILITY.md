PlaceCal is for everyone in a neighbourhood, including people who use a screen reader, a keyboard, voice control, magnification or high contrast settings. Finding out whether you can get into a venue matters as much as finding the event, so this statement covers both: how accessible the PlaceCal websites are, and the access information groups give about their venues and events. It also says how to tell us when something doesn't work.

**Last reviewed: 3 November 2026.**

## What this covers

This statement covers the public PlaceCal websites:

- the nationwide directory at [placecal.org](https://placecal.org)
- local sites such as manchester.placecal.org
- [join.placecal.org](https://join.placecal.org), which tells community groups about PlaceCal

It does not cover the admin area where partners and site admins manage their listings. That has its own accessibility work in progress. If it gets in your way, email us and we'll help.

## How accessible PlaceCal is

PlaceCal meets the [Web Content Accessibility Guidelines (WCAG) 2.2](https://www.w3.org/TR/WCAG22/) at level AA.

That means, for example:

- the first thing a keyboard reaches on every page is a link that skips past the navigation to the main content
- you can use every page with a keyboard alone, and you can always see where you are on the page
- pages fit a screen 320 pixels wide, or zoomed to 400%, without scrolling sideways, and nothing is cut off if you increase text spacing
- links say where they go, even read out of context in a screen reader's list of links
- the event and partner filters keep your place when the list updates, and tell screen readers how many results there are
- menus and filters tell screen readers whether they are open or closed, and maps say what they show
- buttons and other controls are at least 24 pixels across, and form fields, focus outlines and text all have enough contrast
- forms label every field, let your browser fill in your details, and say which field needs fixing

## Access information for venues and events

Every partner on PlaceCal can describe the accessibility of their venue and events: level access or how many steps, toilets, transport, quiet spaces, and anything else that helps you decide whether an event will work for you. The [PlaceCal handbook](https://handbook.placecal.org/how-to/configure-a-partner/) asks partners to be as detailed as they can.

## Content written by partners

Event and partner details come from the groups themselves, often imported straight from their own calendars. That content isn't ours, so it's outside our WCAG claim: in WCAG's terms, this is [partial conformance because of third-party content](https://www.w3.org/TR/WCAG22/#conformance-partial). PlaceCal fits their headings into the page and hides images that have no description, but we can't make sure their link text and image descriptions are clear.

## How we test PlaceCal

- Every change to PlaceCal is checked automatically with [axe](https://github.com/dequelabs/axe-core) on every type of public page, and local site pages are checked on each of our colour themes and on The Trans Dimension's design.
- Every colour theme is checked automatically for text contrast.
- Automated tests use the keyboard alone to reach the skip link, use the filters and custom menus, and check pages at 320 pixels wide.
- We check every page type in a browser for the WCAG 2.2 AA requirements automated tools miss: reflow, text spacing, target size, focus, and the contrast of form fields and focus outlines.
- We test with VoiceOver on macOS in Google Chrome.

## Known limitations

- **Screen readers we haven't tested with.** We have not yet tested PlaceCal with screen readers on Windows (such as NVDA or JAWS), on phones (VoiceOver on iOS or TalkBack on Android), or with VoiceOver in Safari. If you use one of these and something doesn't work, please tell us.
- **Moving around a map.** You move around a map by dragging it. Without dragging, you can use its zoom in and zoom out buttons, double-click a spot to zoom in on it, or select a group of places to zoom to them, and everything shown on a map is also listed on the page as text, with its address. We think this meets WCAG 2.5.7 (dragging movements), but if it doesn't work for you, tell us and we'll add buttons to move the map.

## Tell us about a problem

If something on PlaceCal doesn't work for you, or you need information from it in a different format, email [support@placecal.org](mailto:support@placecal.org). Tell us the page you were on and what happened, and we'll get back to you.

If you think we're missing something WCAG 2.2 AA asks for, please tell us too. We treat that as a bug and fix it.

PlaceCal is open source, so you can also report a problem on [GitHub](https://github.com/geeksforsocialchange/PlaceCal/issues).

## For contributors

Accessibility is part of every change to PlaceCal, not a separate task:

- New public pages and components get an axe check in the accessibility specs.
- All text comes from the locale files, so screen reader labels are translated with everything else.
- Interactive components need to work with a keyboard, report their state (such as whether a menu is open) and move focus somewhere sensible when content changes.

The patterns we use are in [the views guide](https://github.com/geeksforsocialchange/PlaceCal/blob/main/doc/ai/prompts/views.md).

PlaceCal is made by [Geeks for Social Change](https://gfsc.community), who keep this statement up to date.
