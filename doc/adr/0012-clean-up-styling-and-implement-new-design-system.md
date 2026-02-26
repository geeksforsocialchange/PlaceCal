# Clean Up Styling And Implement New Design System

- Author: @idkidk000
- Date: 2026-02-26
- Status: **Proposed**

## Context and Problem Statement

There has been a new PlaceCal design spec'd up and ready to go since April 2023. Implementing it is challenging for the following reasons:

- Non-admin PlaceCal uses Sass for styling. There are 79 unique files with 5,000 LoC.
- Scss files are far away from the pages and components that they style and are not always named well
- They sometimes contain unrelated styles
- There are lots of magic numbers and few notes
- There's a complex web of imports and you need to to refer to multiple files to understand them
- Many of the base styles are of their time and get in the way. But updating them might cause breakage elsewhere (no real way to test), and overriding them uses more LoC
- There's a lot of legacy bloat, e.g. mixins to safely implement features which have been basaeline for a decade, which just add to the noise
- Sass does not support some modern CSS syntax. E.g. `@media (width < $value) {}` is a syntax error (note: this is not the same as `@media (max-width: $value) {}`)
- CSS and Sass are very verbose

We need to implement the new design and get the styles into a maintainable state.

## Decision Drivers

- The styles must be maintainable
- The styles must allow for diverse theming options for partner sites
- It would be nice to have the styles next to or as part of the page or component that they target
- We must not break the site for older devices

## Options

### Stay with Sass

- New default styles and base classes could be written
- New component styles could be written in [sidecar directories](https://viewcomponent.org/guide/templates.html#subdirectory)
- New page styles would still be far away from their targets with nothing to enforce naming correctness

### Switch to vanilla CSS

- Largely it would be the same as the Sass option, but we'd need either
  - A way to bundle the CSS files (which could just be `cat` if we're not checking syntax), or
  - To expose each one as an asset which would be imported into a stylesheet composed on the client. Which would be slow

### Switch to Tailwind

- Kim has already integrated Tailwind into dev and build
- **All** themeable base variables (font weights and families, spacing, border widths and radii, colours, shadows, anything else you can think of) could be be defined in the base stylesheet using [`@theme inline`](https://tailwindcss.com/docs/colors#referencing-other-variables), similar to `app/assets/stylesheets/application.scss`
- All theme variables would be usable in regular Tailwind syntax, e.g. `bg-theme-primary`
- All theme variables would be overridable by partner CSS at runtime
- We could still define reusable classes, e.g. for `.btn`, when useful
- Styling would be mostly done directly in the markup using regular Tailwind syntax
- This would simplify reversing and maintaining styles in the future
- It would make almost all of `/app/assets/stylesheets` redundant

## Notes

- None of the above necessarily _have_ to be done in one go. It's quite possible to only apply the old styles when a class is present and work through pages and components piecemeal
- If you want to add dark/light themes, this is probably the time to do so. It would only be a case of redefining the theme colours and deciding on if you want to just follow the browser's colour scheme or add an auto/light/dark toggle button somewhere
- We need to test the changes on both modern and older browsers
