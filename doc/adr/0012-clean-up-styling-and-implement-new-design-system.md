# Clean Up Pages / Components And Implement New Design System

- Author: @idkidk000 (Jo)
- Deciders: @idkidk000 (Jo) & @kimadactyl (Kim)
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
- There's a lot of legacy bloat, e.g. mixins to safely implement features which have been baseline for a decade, which just add to the noise
- Sass does not support some modern CSS syntax. E.g. `@media (width < $value) {}` is a syntax error (note: this is not the same as `@media (max-width: $value) {}`)
- CSS and Sass are very verbose
- Additionally, there are `.erb` template files for each page and component
- These add another syntax type and more LoC

We need to implement the new design and get the styles into a maintainable state.

## Decision Drivers

- The styles must be maintainable
- The styles must allow for diverse theming options for partner sites
- It would be nice to have the styles next to or as part of the page or component that they target
- We must not break the site for older devices
- It would be nice to combine the `.rb` classes with the `.erb` templates

## Options

### Styling

- Stay with Sass
  - New default styles and base classes could be written
  - New component styles could be written in [sidecar directories](https://viewcomponent.org/guide/templates.html#subdirectory)
  - New page styles would still be far away from their targets with nothing to enforce naming correctness

- Switch to vanilla CSS
  - Largely it would be the same as the Sass option, but we'd need either
    - A way to bundle the CSS files (which could just be `cat` if we're not checking syntax), or
    - To expose each one as an asset which would be imported into a stylesheet composed on the client. Which would be slow

- Switch to Tailwind
  - Kim has already integrated Tailwind into dev and build and migrated the admin frontend
  - **All** themeable base variables (font weights and families, spacing, border widths and radii, colours, shadows, anything else you can think of) could be be defined in the base stylesheet using [`@theme inline`](https://tailwindcss.com/docs/colors#referencing-other-variables), similar to `app/assets/stylesheets/application.scss`
  - All theme variables would be usable in regular Tailwind syntax, e.g. `bg-theme-primary`
  - All theme variables would be overridable by partner CSS at runtime
  - We could still define reusable classes, e.g. for `.btn`, when useful
  - Styling would be mostly done directly in the markup using regular Tailwind syntax
  - This would simplify reversing and maintaining styles in the future
  - It would make almost all of `/app/assets/stylesheets` redundant

### Components

- Stay with ActiveRecord classes and `.erb` templates
  - Nothing changes in this regard, we just get the benefits of refactoring styling
- Migrate to Phlex
  - The `.erb` templates would largely be merged into the `.rb` classes and modules
  - Reduces cognitive overhead from having many multiple syntax types
  - Reduces filesystem and LoC bloat
  - Simplifies writing new components
  - Can also integrate typing with the `literal` gem, which further reduces cognitive overhead and improves developer experience

## Notes

- None of the styling options above necessarily _have_ to be done in one go. It's quite possible to only apply the old styles when a class is present and work through pages and components piecemeal
- It's also possible to gradually migrate over to Phlex (from Quinn in the Discord)
- If you want to add dark/light themes, this is probably the time to do so. It would only be a case of redefining the theme colours and deciding on if you want to just follow the browser's colour scheme or add an auto/light/dark toggle button somewhere
- We need to test the changes on both modern and older browsers (I now have [a way to do this](https://github.com/idkidk000/old-browsers-docker))

## Tailwind & Phlex Partner Theming Options

- Partner themes can provide a CSS file which overrides the base Tailwind variables. This allows for simple overrides of
  - Animation timing, easing functions
  - Border widths, radii
  - Colours
  - Shadows (if we use them)
  - Spacing
  - Fonts (using either system font families or faces which we already include in the base CSS)
- They could provide inline [`@font-face`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@font-face) declarations and override the appropriate theme variables to use custom fonts
- We'll continue to use targetable class names for elements and use [`grid-template`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/grid-template) for layout where appropriate. This allows for
  - Redefining layouts - the nav bar could be moved to the left or bottom, or the `event--list` could have its children reordered
  - Adding [filters](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/filter) to all event or partner images - e.g. to increase contrast, add a blur, or adjust colours
  - Swapping out block colours for gradients - e.g. on the nav bar or hero
- Defining an entire component in a single file makes it easier to conditionally output child elements based on partner or site settings. We could control this with a nilable hash of field_name, boolean (should we display the field) which is stored in `partners` or `sites` and can be configured through the admin frontend. Nil would mean "use the defaults". For example:
  - `event--list` could optionally display an event image, a truncated description, and hide the location
- If necessary, we could even just not output the Tailwind `<style/>` tag in in `app/views/layouts/application.html.erb` according to partner/site configuration. Tailwind classes would be inert and a partner theme would essentially start from a blank slate
- We could build an admin UI to create your own theme
  - Provide one colour and we calculate the complementary and contrast colours by rotating the hue and adjusting lightness in [LCH colour space](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/color_value/lch) so that perceived brightnesses are consistent and predictable. E.g. in RGB space, #0F0 (green) is much brighter than #00F (blue) despite the channel values being equivalent. LCH fixes that
  - Or they can provide all the colours if they prefer
  - Sliders (range inputs) for spacing, font sizes, etc
  - Options for border styles
  - Provide font links, e.g. from https://openfont.org/ or https://fonts.google.com/. We could download the font, store it as an asset, and include it in their CSS
  - Checkboxes for which fields to display on which components
  - On save, we could store everything to the DB as a JSON object and generate a CSS file to include in `app/views/layouts/application.html.erb`

## Decision Outcome

### Components

Kim has migrated everything (admin and non-admin) over to Phlex and we both like it

### Styles

We're both happy for me to migrate non-admin styles to Tailwind

## References

- [Tailwind](https://tailwindcss.com/docs)
- [Phlex](https://www.phlex.fun/docs)
- [Literal](https://literal.fun/docs)
