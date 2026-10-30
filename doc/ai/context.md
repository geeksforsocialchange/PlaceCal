# AI Agents Context

This project optionally supports AI coding assistants with specialized agents for Rails development.

## Project Information

_Exact versions live in `Gemfile` / `Gemfile.lock` / `.ruby-version` — the source of truth. This list is for orientation; don't pin versions here, they drift._

- **Rails**: 8
- **Ruby**: see `.ruby-version`
- **Project Type**: Full-stack Rails
- **Component Framework**: Phlex (with Literal typed props)
- **Test Framework**: RSpec (+ Cucumber)
- **GraphQL**: Enabled
- **Turbo/Stimulus**: Enabled

## Development Guidelines

When working on this project:

- Follow Rails conventions and best practices
- Write tests for all new functionality
- Use strong parameters in controllers
- Keep models focused with single responsibilities
- Extract complex business logic to service objects (e.g., `app/queries/`)
- Ensure proper database indexing for foreign keys and queries
- For site-specific features: see @doc/extensions.md. Extensions are Rails engines with no models or migrations; they register themes (stylesheets, views, components, locales)

## Pull requests

Every PR gets exactly one Release Drafter category label, or it lands uncategorised in the release notes: `enhancement`, `fix`, `security`, `maintenance`, `dependencies` or `docs` (see `.github/release-drafter.yml`). `dependencies` is for PRs that only update a dependency or pin (Renovate and the extension pin PRs label themselves); code tidying, refactors and tooling are `maintenance`. The autolabeler only matches title prefixes like `fix`, `feat` and `chore`, so add the label yourself with `gh pr create --label <label>` or `gh pr edit <number> --add-label <label>`. `enhancement` makes the next release a minor version; the others are patches.

## Releases

Production deploys only when a GitHub release is published; merging to `main` deploys staging. Release Drafter keeps a draft release whose body is the categorised list of merged PRs.

- **Notes:** before publishing, add a short plain-language summary of the release (a few sentences or bullets on what changed for people using PlaceCal) at the top of the draft body, above Release Drafter's `## What's changed` list. Keep that list and the "Full changelog" link exactly as generated; never replace the body with only the summary.
- **Publishing:** set `tag_name` and `target_commitish` to the full SHA of the commit to release in the same API call that publishes, then check the tag exists (`gh api repos/:owner/:repo/git/ref/tags/<tag>`).
- **Version:** any `enhancement` PR makes it a minor release; otherwise it's a patch.

## CRITICAL: Internationalization (i18n)

**NEVER hardcode user-facing strings in views, components, controllers, or JavaScript.** Always use locale keys.

### In Ruby (views, components, controllers)

Use `t('key')` for all display text:

```ruby
# Good
h2 { t('directory.partners.show.upcoming_events') }
sidebar_heading(t('directory.sidebar.opening_times'))

# Bad
h2 { 'Upcoming events' }
sidebar_heading('Opening times')
```

Use `Model.model_name.human(count:)` for model names and `attr_label(:model, :attribute)` for field labels.

### In JavaScript (Stimulus controllers)

Pass localized strings via data attributes from Rails — never hardcode in JS.

### Locale file structure

- `config/locales/en.yml` — ActiveRecord models/attributes, site metadata, public/directory UI strings
- `config/locales/admin.en.yml` — Admin interface strings

### Specialist prompt files

Detailed per-domain rules live in `doc/ai/prompts/`. Consult the relevant one when working in a specific area:

- `views.md` — Phlex components, i18n patterns, accessibility
- `controllers.md` — Strong params, response handling, i18n
- `tests.md` — RSpec patterns, factory usage, no `sleep` in tests
- `stimulus.md` — JS controllers, data attributes for i18n
- `models.md` — AR patterns, migrations, validations
- `graphql.md` — Schema design, resolvers, authorization

### Plugins (capabilities)

`doc/ai/plugins/` holds vendored Claude Code plugins, installed into your local
`.claude/` by `bin/setup-ai`. See `doc/ai/plugins/README.md`.

- **`better-stimulus`** (agent) — StimulusJS best practices for our native-JS /
  importmap setup. Use when writing or reviewing a Stimulus controller.
- **`rails-hotwire-driver`** (skill) — drive the running dev server from the
  terminal to **verify a change actually works** before claiming it does (see the
  Verification Rules in `CLAUDE.md`). It exercises the server contract
  (controllers, redirects, Turbo Streams, the SQL/errors in `development.log`)
  but does **not** run JavaScript. The verify loop: fast server-side assertions
  via the skill's curl scripts, then for anything JS-dependent (Stimulus, DOM,
  maps) verify in Claude in Chrome (our `lvh.me` standard), or optionally bridge
  the logged-in session into a Playwright MCP for a scripted browser.
- **`rubocop-autocorrect`** (hook) — a `PostToolUse` hook (source in
  `doc/ai/hooks/`, registered in `.claude/settings.json` by `bin/setup-ai`) that
  runs `rubocop -A` on every Ruby file the assistant edits and feeds any
  remaining offenses back to fix. Keeps style automatic — don't hand-fix RuboCop.

## Asset Pipeline

### JavaScript (importmap-rails)

Both admin and public interfaces use **importmap-rails** with native ES modules (no build step required).

- **Entrypoint**: `app/javascript/application.js`
- **Controllers**: `app/javascript/controllers/*.js`
- **Controller mixins**: `app/javascript/controllers/mixins/*.js`
- **Configuration**: `config/importmap.rb`
- Changes take effect on browser refresh (no build needed)
- External dependencies loaded from CDN (jsdelivr `/+esm`; avoid esm.sh, whose per-User-Agent builds break maps in Safari):
  - `tom-select` - Enhanced select inputs
  - `leaflet` - Map rendering
  - `maplibre-gl` - Vector tile map styling
  - `@hotwired/turbo-rails` - Turbo Drive/Frames/Streams
- Stimulus controllers are shared between admin and public sites
- No lodash or jQuery - use native JS instead

### Tailwind CSS (Admin interface)

- **Source**: `app/tailwind/admin_tailwind.css`
- **Output**: `app/assets/builds/admin_tailwind.css`
- **Build command**: `yarn build` (or `yarn css-admin`)
- Linked from `app/views/layouts/admin/application.rb`
- New Tailwind classes only work after rebuilding CSS (Tailwind scans templates)

### Tailwind CSS (Public site)

- **Source**: `app/tailwind/public_tailwind.css`, the entry point: Tailwind, Leaflet's CSS from npm, the `@source` list, then the partials in `app/tailwind/public/`:
  - `_theme.css`: design tokens (the override contract themes rely on)
  - `_themes.css`: the built-in colour themes, picked by `data-theme` on `<html>`
  - `_fonts.css`, `_variants.css` (custom variants), `_base.css` (element defaults), `_utilities.css` (named utilities)
  - `components/`: the few unlayered component rules, one file per component, imported in a fixed order
- **Output**: `app/assets/builds/public_tailwind.css`, built by `yarn build`
- MapLibre's CSS loads from jsDelivr at the version `config/importmap.rb` pins, added by the map's Stimulus controller
- `yarn build` also copies Leaflet's images from npm into `app/assets/builds/images/`, where Leaflet's CSS looks for them

### Common Issues

1. **JS changes not appearing**: Just refresh browser (no build needed for JS)
2. **New Tailwind classes not working**: Run `yarn build`, hard refresh browser
3. **Browser caching**: Use `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows) for hard refresh

### Development Workflow

When running `bin/dev`, the Procfile.dev starts a watcher for Tailwind CSS. JavaScript doesn't need a watcher since it uses importmap.

## Tailwind CSS Best Practices

### Components own their look

Public UI primitives live in `app/components/ui/` and carry their styling as Tailwind utility maps inside the component (`UI::Button`, `UI::Pill`, `UI::RuledHeading`). Call sites pick a variant or size by prop; they don't pass size, colour or spacing classes.

```ruby
# Good
UI::RuledHeading(caps: true, rule: :full, size: :lg) { t('partners.show.contact_heading') }
UI::Cluster(gap: :md, row_gap: :sm) { ... }

# Avoid
UI::RuledHeading(class: 'text-xl my-5.5') { ... }
div(class: 'flex flex-wrap items-center gap-y-2 gap-x-4') { ... }
```

Layout goes through `UI::Cluster` (a wrapping row) and `UI::Stack` (a column whose gap replaces its children's margins), with gaps from one scale (`:xs` to `:xl`). Hover and focus utilities are generated like any other, as long as the file is in an `@source` path. Write custom CSS in `app/tailwind/public/components/` only for what utilities can't express, such as markup a library builds.

### Stimulus Controller Visibility Toggling

When toggling element visibility in Stimulus controllers, prefer `style.display` over `classList.toggle("hidden")` when using flexbox:

```javascript
// Good: Works reliably with inline-flex
element.style.display = visible ? "inline-flex" : "none";

// Problematic: CSS specificity issues with Tailwind's hidden class
element.classList.toggle("hidden", !visible);
```
