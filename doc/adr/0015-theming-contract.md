# A Theming Contract: Tokens, Scopes and Parts, and Replacement Points

- Author: @kimadactyl (Kim)
- Date: 2026-10-30
- Status: **Accepted**

## Context and Problem Statement

Extension themes (ADR 0012's design system, `doc/extensions.md`) restyle PlaceCal's public pages with their own stylesheet, linked after core's. The written contract says themes are "Tailwind plus CSS custom properties that override core's tokens", plus a set of settings that swap whole views or components.

In practice the main theme, Trans Dimension, has about 6,800 lines of CSS that restyle core by targeting class names in core's markup, and core carries about 100 BEM-style class names (`event__fullinfo`, `hero__back`, `join-card` and so on) that exist only so the theme can find things. Nothing says which names are safe to use. The result:

- **Themers reverse-engineer HTML.** They read core's rendered markup and guess what to hook onto.
- **Core refactors break themes silently.** On 30 October 2026 alone, four core changes broke Trans Dimension: a new wrapper around the event buttons, the contact form moving into layout components, the link rule moving into a CSS layer, and the hero tagline gaining classes.
- **Core can't tidy its own markup** without first checking every theme's selectors, so the hooks freeze its structure. An audit of the same day could call only 1 of 109 such names safe to delete.

Projects that handle this well (Shoelace, Ark UI, Radix, shadcn/ui, GOV.UK Frontend, Shopify, Spree) give themes a small, declared set of hooks with a promise attached, and keep everything else internal. The research behind this decision is summarised under References.

## Decision Drivers

- **A good experience for themers:** a theme should be written from a published list of hooks, not by reading core's HTML.
- **Core free to refactor:** utility classes and markup structure must be core's to change.
- **Existing themes keep their look:** the system has to be expressive enough that Trans Dimension can look the same through it.
- **Fit the stack:** Rails engines as themes, Phlex components, Tailwind v4 with CSS custom-property tokens, Lookbook for component previews.
- **Early alpha:** PlaceCal has no external theme authors yet, so the contract can be put in place now without a migration period.

## Considered Options

1. **Keep class names as the hook, and document them.** Cheapest, but every utility refactor stays a theme risk, and class names mix public hooks with internal styling.
2. **A namespaced class prefix as the public API** (`pc-hero__title`, as GOV.UK Frontend does with `govuk-`). Familiar, but public classes sit among Tailwind utilities and are hard to tell apart.
3. **Data attributes as the public API** (chosen). Every component marks its meaningful pieces with `data-scope` and `data-part`, the convention Ark UI and Zag use. shadcn/ui's `data-slot` was considered and rejected because "slot" already means a content insertion point in Phlex and web components.
4. **Replace components wholesale.** Themes ship their own copies of core components. Honest for big redesigns, but copies drift from core and carry the upgrade pain Spree, Decidim and Shopify all report.

## Decision

Themes get three public layers. Everything else, including every class name and any markup structure not named here, is internal and may change in any release.

1. **Tokens.** The CSS custom properties in `app/tailwind/public/_theme.css` (colour, font, radius, shadow, type scale). A theme overrides their values. Per-component tokens are added only when a theme needs one.
2. **Scopes, parts and states.**
   - `data-scope="<name>"`: one scope per Ruby class, in kebab-case (`hero`, `event`, `event-details`, `pill`). A component that renders differently in different contexts says so with `data-variant` on its root, not with a second scope.
   - `data-part="<name>"`: a named piece, in kebab-case. The outer element is `root`. **Parts are named by meaning, never by layout:** `title`, `details` and `address` are parts; `columns` and `fullinfo` are not.
   - **Every part element carries both attributes,** so a theme writes `[data-scope="hero"][data-part="title"]` and nested components can't collide. Across scopes a theme uses a descendant selector: `[data-scope="hero"][data-part="root"] [data-scope="pill"]`.
   - **States and variants:** `data-state` and `data-variant` on the part they describe, or the ARIA attribute where one already says the same thing (`aria-current`, `aria-expanded`).
   - **Core styles parts only with layered utilities,** never unlayered CSS, so theme CSS always wins.
3. **Replacement points.** Theme settings that swap a whole view or component (`homepage_view`, `footer`, `page`, `head`). Where a theme needs different structure, core adds a replacement point rather than exposing layout as parts.

Core declares each component's scope and parts in Ruby (`theme_scope :hero, parts: [...]`), from a module shared by components and views. That declaration is the single source for:

- a spec that every declared part renders;
- a theming panel per component in Lookbook, listing its scope, parts, states and the tokens it reads;
- a contract list that each theme's own specs check its CSS against.

**BEM hook names are retired as each component gets its scope,** with the theme moved over in the same step. No deprecation window during alpha. Trans Dimension is moved onto the contract so it looks the same, and any gap is closed in core's contract (a part, a token or a replacement point), not by keeping class hooks. Mossley, which is frozen, is not migrated; its class hooks stop working when the components they target are converted.

**Once the contract is declared stable**, renaming or removing a scope, part, state or token follows GOV.UK Frontend's model: the old name works alongside the new one for at least one minor release and one month, the release notes say what to change, and removal happens in a release marked as breaking for themes. Until then, the contract can change in any release, with the theme updated alongside.

The rollout starts with a pilot on the hero, the event card and page, and the UI primitives they render. The pilot also tests the contract directly: someone with only the docs and the Lookbook panels restyles the hero, noting everywhere they had to read markup.

## Consequences

### Positive

- Themers work from a published list of hooks, visible in Lookbook, instead of reading core's HTML.
- Core can change utility classes and markup freely, and stops carrying BEM names whose only job is to be found.
- A theme's CI fails when it targets a scope or part core no longer declares, rather than the theme breaking silently in production.
- The same declaration documents, tests and checks the contract, so the three can't drift apart.

### Negative

- Every themable component needs its scope and parts declared and kept up to date, and part names become a commitment once the contract is stable.
- Trans Dimension has to be rewritten component by component, and must be on the contract for every converted component before the core release that converts it.
- Mossley loses its styling on converted components unless it is migrated or retired.
- Attribute selectors are wordier than class selectors in theme CSS.

## References

- Research on how other projects let themes hook in, with sources: Spree 5 storefront themes, Shopify Online Store 2.0, WordPress block themes, Discourse theme components and plugin outlets, shadcn/ui `data-slot`, Ark UI `data-scope`/`data-part` ([styling guide](https://ark-ui.com/docs/guides/styling)), Shoelace CSS parts ([customizing](https://shoelace.style/getting-started/customizing)), GOV.UK Frontend versioning and deprecation.
- ADR 0012: Clean up pages and components, and implement the new design system.
- `doc/extensions.md`: the extension and theme contract this ADR extends.
