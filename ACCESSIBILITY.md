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

## Known problems

- **News images have no text description.** Pictures on news articles and the news listing have no alt text, so a screen reader cannot say what they show.
- **The site name is read twice.** On local sites, screen readers read the site's name twice at the top of each page.
- **Maps.** We have not yet tested the maps with a keyboard or a screen reader. Everything shown on a map is also listed on the page as text, with its address.
- **Content written by partners.** Event and partner details come from the groups themselves, often imported straight from their own calendars. We can't always make sure that content has clear headings, descriptive link text or descriptions of its images.
- **Sites with their own design.** Some local sites, such as The Trans Dimension, use a design of their own. Our automated accessibility checks don't cover those designs yet.

## How we test PlaceCal

- Every change to PlaceCal is checked automatically with [axe](https://github.com/dequelabs/axe-core) on every type of public page, and local site pages are checked on each of our colour themes.
- Every colour theme is checked automatically for text contrast.
- Automated tests use the keyboard alone to reach the skip link and to filter partners.
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
