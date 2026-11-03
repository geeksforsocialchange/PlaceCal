PlaceCal should be usable by everyone, including people who use a screen reader, a keyboard, voice control, magnification or high contrast settings. This statement says how well we do that, what we know doesn't work yet, and how to tell us about a problem.

**Last reviewed: 3 November 2026.**

## What this covers

This statement covers the public PlaceCal websites:

- the nationwide directory at [placecal.org](https://placecal.org)
- local sites such as manchester.placecal.org
- [join.placecal.org](https://join.placecal.org), which tells community groups about PlaceCal

It does not cover the admin area where partners and site admins manage their listings. That has its own accessibility work in progress. If it gets in your way, email us and we'll help.

## How accessible PlaceCal is

We aim to meet the [Web Content Accessibility Guidelines (WCAG) 2.2](https://www.w3.org/TR/WCAG22/) at level AA. PlaceCal partially meets that standard. The problems we know about are listed below.

On every public page:

- the first thing a keyboard reaches is a link that skips past the navigation to the main content
- the links PlaceCal adds say where they go, even out of context, such as in a screen reader's list of links
- the event and partner filters keep your place when the list updates, and tell screen readers how many results there are
- menus and filters tell screen readers whether they are open or closed
- maps work with a keyboard, and the map and each place on it are named for screen readers

## Known problems

- **Content written by partners.** Event and partner details come from the groups themselves, often imported straight from their own calendars. PlaceCal fits their headings into the page and hides images that have no description, but we can't make sure their link text and image descriptions are clear.

## How we test PlaceCal

- Every change to PlaceCal is checked automatically with [axe](https://github.com/dequelabs/axe-core) on every type of public page, and local site pages are checked on each of our colour themes and on The Trans Dimension's design.
- Every colour theme is checked automatically for text contrast.
- Automated tests use the keyboard alone to reach the skip link and to filter partners, and we have tested the maps with a keyboard.
- We test with VoiceOver on macOS in Google Chrome.

We have not yet tested with screen readers on Windows (such as NVDA or JAWS), on phones (VoiceOver on iOS or TalkBack on Android), or with VoiceOver in Safari. We haven't finished checking every page by hand against each WCAG 2.2 AA requirement, and we fix what we find as we go.

## Tell us about a problem

If something on PlaceCal doesn't work for you, or you need information from it in a different format, email [support@placecal.org](mailto:support@placecal.org). Tell us the page you were on and what happened, and we'll get back to you.

PlaceCal is open source, so you can also report a problem on [GitHub](https://github.com/geeksforsocialchange/PlaceCal/issues).

## For contributors

Accessibility is part of every change to PlaceCal, not a separate task:

- New public pages and components get an axe check in the accessibility specs.
- All text comes from the locale files, so screen reader labels are translated with everything else.
- Interactive components need to work with a keyboard, report their state (such as whether a menu is open) and move focus somewhere sensible when content changes.

PlaceCal is made by [Geeks for Social Change](https://gfsc.community), who keep this statement up to date.
