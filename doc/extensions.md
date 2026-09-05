# Writing Extensions

PlaceCal extensions are Rails engines that plug into the core application without modifying it. An extension registers a theme: a set of stylesheets, views, components, locale files, and configuration that customize PlaceCal's appearance and behaviour for a specific site or installation.

## The extension contract

If a second partnership could want it, it is a core feature and gets built generically. If only this site wants it, it is views, CSS, assets and copy in an extension. Extensions contain no models, no migrations, no business logic.

Two extensions exist today and core loads both at once: the Trans Dimension and Marvellous Mossley. Mossley used to be the one site core knew by name, served by a `custom` theme that resolved its stylesheet and map style from the site slug, a homepage view in `app/views/sites/`, and a branch in `SitesController`. All of it is now `placecal-theme-mossley`, and core has no per-site special cases left. A bespoke site is an extension; there is no other route.

Extensions are Rails engines generated with `rails plugin new --full` (NOT `--mountable`: the engine must not isolate its namespace or routes, it plugs into the host app) and trimmed to the layout below.

## Trust

An extension is a Rails engine loaded into the same process as the application. Nothing sandboxes it: its `lib/` is on the load path, its initializers run at boot, and any Ruby it ships runs with the application's full privileges, including the database, the credentials and the network. A theme is therefore a code dependency, not content, and it is reviewed the way any other gem in the `Gemfile` is reviewed.

That gives four rules:

1. A theme is added or bumped only by a maintainer, through a change to core's `Gemfile`. There is no upload path, no admin screen and no runtime install. Adding or moving a theme is a pull request against core, reviewed and merged like any other.
2. A theme is pinned by git tag, never by branch, and `Gemfile.lock` records the exact commit the tag pointed at. A retagged release changes the lockfile, so a substituted release shows up in the diff instead of arriving silently.
3. A theme comes from a repository owned by GFSC with branch protection on its default branch, so the code behind a tag has been through review in its own repo too.
4. A theme stays inside the extension contract: views, components, assets, locales, content and rake tasks only, and no models, migrations, controllers, routes or business logic.

Rule 4 is enforced twice. Reviewers check it on the pull request that adds or bumps the gem, and `bin/check-extension-tree` checks it mechanically in CI: it walks every gem in the `Gemfile`'s `:extensions` group, lists the files the gem ships, and fails the `lint` job if any of them falls outside the allowlist. Anything under `app/models`, `app/controllers`, `db/`, `config/routes.rb` or `config/initializers`, and any Ruby under `lib/` beyond the engine's own entry point, engine and version files, fails the build. The guard is a backstop for review, not a replacement for it: it constrains where a theme may put code, not what that code does.

If you want a theme that genuinely cannot run code, that is a different mechanism from a Rails engine, and it is tracked in [issue #3489](https://github.com/geeksforsocialchange/PlaceCal/issues/3489). Until it exists, treat every theme as trusted code.

## Layout

```
<ext>/
  lib/
    <ext>.rb              # Module definition and namespace
    <ext>/engine.rb       # Rails engine with Phlex autoload and theme registration
  app/
    views/<ext>/          # Phlex views (autoloaded as <Ext>::Views)
    components/<ext>/     # Phlex components (autoloaded as <Ext>::Components)
    assets/builds/<ext>/  # Prebuilt CSS (committed to repo)
  config/
    locales/en.yml        # Locale strings (loaded automatically by Rails)
```

An extension normally has no controllers: core's controllers serve every page and the extension supplies views, components and copy. An engine _may_ draw routes in its own `config/routes.rb` (they load after core's `config/routes.rb`, so they win over core's `/:slug` theme-page catch-all, which is appended last by `config/initializers/site_page_routes.rb`), but a theme that needs new routes is usually a sign the feature belongs in core. Core's fixture engine under `spec/` has both, for testing.

## The engine

An extension's engine is an ordinary Rails engine that includes `PlaceCal::Extension`. That one include carries everything every extension used to copy: the Zeitwerk directories for its Phlex namespaces, the host and theme guards, and theme registration.

```ruby
# lib/my_ext.rb
module MyExt
  # Phlex namespaces. Core owns Views and Components; an extension owns
  # <Extension>::Views and <Extension>::Components.
  module Views; end

  module Components
    extend Phlex::Kit
  end
end

# Two lines, so an installation whose core predates the shared engine
# infrastructure fails by name rather than with a NameError from a class body.
abort('placecal-theme-my-ext needs a PlaceCal with PlaceCal::Extension; see "Minimum core" in README.md.') unless defined?(PlaceCal::Extension)

require_relative "my_ext/version"
require_relative "my_ext/engine"

# lib/my_ext/engine.rb
module MyExt
  class Engine < ::Rails::Engine
    # Not isolate_namespace: an extension plugs into the host app's routes,
    # helpers and layout rather than living behind a mount point.
    include PlaceCal::Extension

    required_settings %i[stylesheet homepage_view map_style]

    theme :my_ext do |theme|
      theme.stylesheet    "my_ext/theme"
      theme.homepage_view "MyExt::Views::Home"
      theme.map_style     "my_ext"
    end
  end
end
```

`include PlaceCal::Extension` derives the extension's name from the engine's own namespace (`MyExt` gives `my_ext`) and gives the engine:

- **Phlex autoloading.** `app/views/my_ext` is pushed onto Zeitwerk under `MyExt::Views` and `app/components/my_ext` under `MyExt::Components`. Rails does not autoload `app/views`, and it autoloads `app/components` under the top-level namespace, so the directories need pushing with explicit namespaces; core does the same for its own `Views` and `Components` in `config/initializers/phlex.rb`. Only directories the extension actually ships are pushed, so an extension built entirely from core's components ships no `app/components` and needs no configuration for that.
- **The host guard.** `required_settings` is the list of theme DSL settings the engine uses. Before registering, the engine checks that the host has `PlaceCal::Extensions.register_theme` and that `PlaceCal::Theme` answers every listed setting, and raises `PlaceCal::Extension::UnsupportedHost` naming what is missing. Without it an old core fails with a bare `NoMethodError` from inside an initializer, which says nothing about what the installation needs.
- **Registration.** The `theme` block is applied to the `PlaceCal::Theme` at boot. It is also callable on its own as `MyExt::Engine.configure_theme(PlaceCal::Theme.new(:throwaway))`, which is how an extension's own contract spec asserts what it registers without booting twice.

### Minimum core

`PlaceCal::Extension` is required by core's `config/application.rb` before Bundler requires the extension gems, so on a core new enough to have it the constant is defined by the time an engine's class body runs. On an older core it is not defined at all, and `include PlaceCal::Extension` would raise a `NameError` from the middle of a class body. Keep the two-line `defined?(PlaceCal::Extension)` guard in `lib/<ext>.rb` shown above: it turns that into one sentence naming the gem and the requirement, and it is the reason the guard survives moving the machinery into core. Say which core version the theme needs in a "Minimum core" section of the extension's README.

## Theme registration

The `theme` block receives the `PlaceCal::Theme` and fills in the slots the theme uses:

```ruby
theme :my_ext do |theme|
  theme.stylesheet    "my_ext/theme"
  theme.homepage_view "MyExt::Views::Home"
  theme.map_style     "my_ext"
  theme.head          "MyExt::Components::Head"
  theme.footer        "MyExt::Components::Footer"
  theme.font_stylesheet "https://use.typekit.net/abcdefg.css",
                        preconnect: %w[https://use.typekit.net https://p.typekit.net]
  theme.theme_color   "#f19089"
  theme.background_color "#040f39"
  theme.icons         favicon_32: "my_ext/favicons/favicon-32x32.png",
                      favicon_16: "my_ext/favicons/favicon-16x16.png",
                      apple_touch_icon: "my_ext/favicons/apple-touch-icon.png",
                      mask_icon: "my_ext/favicons/safari-pinned-tab.svg",
                      mask_icon_color: "#FF7AA7",
                      icon_192: "my_ext/favicons/android-chrome-192x192.png",
                      icon_512: "my_ext/favicons/android-chrome-512x512.png"
  theme.og_image      "my_ext/og.png", width: 1200, height: 675
  theme.nav_cta       "my_ext.nav.donate", "https://example.org/donate"
  theme.nav_join      false
  theme.menu_label    true
  theme.event_filter_style :day_strip
end
```

Views inherit `Views::Base` to get Rails helpers, `t()` translations, and the core `Components` kit. Components inherit `Components::Base`.

Every setting is optional, and the full list is defined in `lib/placecal/theme.rb`:

| Setting              | Value                                                                                                                      | Default              | What it does                                                                                                                                                                                                                                                                                                                                                                                           |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `stylesheet`         | asset logical path without the extension                                                                                   | none                 | Linked in `<head>` after core's stylesheets. Skipped with an error in the log if the asset does not resolve, so a stale build cannot take the site down.                                                                                                                                                                                                                                               |
| `homepage_view`      | Phlex view class name (String)                                                                                             | core's site homepage | Renders the site's homepage.                                                                                                                                                                                                                                                                                                                                                                           |
| `map_style`          | MapLibre style name                                                                                                        | `pink`               | See "Map styles" below.                                                                                                                                                                                                                                                                                                                                                                                |
| `head`               | Phlex component class name                                                                                                 | none                 | Rendered inside `<head>`, for fonts, meta tags and the like.                                                                                                                                                                                                                                                                                                                                           |
| `footer`             | Phlex component class name                                                                                                 | core's footer        | Replaces core's site footer. Constructed with `new(site:, navigation:)`.                                                                                                                                                                                                                                                                                                                               |
| `theme_color`        | hex colour, e.g. `"#f19089"`                                                                                               | none                 | `theme-color` value in the web manifest, and the `<meta name="theme-color">` on the site's pages.                                                                                                                                                                                                                                                                                                      |
| `background_color`   | hex colour, e.g. `"#040f39"`                                                                                               | `theme_color`        | Splash `background_color` in the web manifest, for themes whose splash differs from their chrome colour.                                                                                                                                                                                                                                                                                               |
| `icons`              | keyword paths: `favicon_32`, `favicon_16`, `apple_touch_icon`, `mask_icon`, `icon_192`, `icon_512`, plus `mask_icon_color` | none                 | The theme's own favicons, touch icon, Safari mask icon and manifest icons. Any icon set replaces core's `favicon.png` and `apple-touch-icon.png` in `<head>`; `icon_192`/`icon_512` replace the manifest icons. `mask_icon_color` is a colour, not a path: it is the `color` attribute of `<link rel="mask-icon">`. Unknown keys, and a `mask_icon_color` that is not a colour, raise `ArgumentError`. |
| `og_image`           | asset logical path plus `width:` and `height:`                                                                             | none                 | A static Open Graph share image for the theme's sites, in place of core's generated share card.                                                                                                                                                                                                                                                                                                        |
| `nav_cta`            | locale key and URL                                                                                                         | none                 | A call-to-action link (for example Donate) rendered as the last item in the site nav.                                                                                                                                                                                                                                                                                                                  |
| `nav_join`           | boolean                                                                                                                    | `true`               | Whether the derived nav includes the Join link when the site takes enquiries. Set `false` when the theme's own footer carries it.                                                                                                                                                                                                                                                                      |
| `event_filter_style` | `:date_picker` or `:day_strip`                                                                                             | `:date_picker`       | Which date control the events filter renders.                                                                                                                                                                                                                                                                                                                                                          |
| `menu_label`         | boolean                                                                                                                    | `false`              | Whether the mobile menu toggle shows a "Menu" text label next to the icon.                                                                                                                                                                                                                                                                                                                             |
| `page`               | slug, Phlex view class name, optional `nav_label_key:`                                                                     | none                 | A static content page served at `/<slug>`. Repeatable; see "Theme pages" below.                                                                                                                                                                                                                                                                                                                        |

Class names are given as strings and resolved lazily, so registration can run before autoloading is ready; a name that no longer resolves is logged and core's default renders instead.

## Theme pages

Static copy (About, Get involved, a privacy notice) belongs to the theme, not to core: core stores no page content and has no page editor. A theme declares which paths it serves and which Phlex view renders each one.

```ruby
theme.page "about", "MyExt::Views::About", nav_label_key: "my_ext.nav.about"
theme.page "privacy", "MyExt::Views::Privacy"
```

- The page is served at `/about` on every site using the theme, by core's `/:slug` catch-all. The bare path only: `/about.json` and `/about.html` do not route. The catch-all is constrained to the slugs registered themes serve, so any other single-segment path is a routing 404 that never reaches a controller.
- The view is constructed with `new(site:)` and inherits `Views::Base` like any other theme view. Everything about the page, including its wrapper element and any `page page--about` style classes, is the view's own business.
- `nav_label_key` is a locale key. A page that has one is listed in the derived site nav and footer nav under `t(key)`, in registration order, after the News link. A page without one is served but not linked.
- Every registered page is listed in the site's sitemap (no `lastmod`, since there is no record to date).
- Slugs are lowercase letters, numbers and hyphens; anything else raises `ArgumentError` at registration.
- A slug matching a core route (`events`, `partners`, `news`, and so on) is never served: the `/:slug` catch-all is appended after every other route, so the core route wins and the theme's page is simply unreachable. Pick a slug core does not already own. `privacy` is the exception worth knowing: core's `/privacy` prefers the theme's page when it registers one and falls back to core's own copy otherwise.
- Class names are strings, resolved lazily. A name that no longer resolves is logged and the page 404s, rather than taking the site down.

### Markdown content pages

A page whose content is markdown files in the extension's `content/` directory subclasses core's `Views::ThemeContentPage` and declares a content root, a slug, a title and the files:

```ruby
class MyExt::Views::About < Views::ThemeContentPage
  content_root MyExt::Engine.root.join("content")
  slug         "about"
  title        "my_ext.about.title"
  description  "my_ext.site.description"

  markdown "about/main.md"
  markdown "about/accessibility.md", heading: "my_ext.about.accessibility"
end
```

That renders the `page page--<slug>` wrapper with `data-page-slug`, an `h1` and a `.markdown-content` column, and each file in declaration order under its heading. Headings are locale keys, so section names stay translatable while the body stays markdown. Every declaration is inherited, so an extension with several pages can put `content_root` on a base class of its own and each page declares only what is its own; a page that needs more than headings and blocks overrides `page_body` and calls `markdown "file.md"` itself.

Markdown goes through Kramdown and `Rails::HTML5::SafeListSanitizer`, and each file's rendered HTML is cached: in development the cache key carries the file's mtime, so an edit is picked up without a restart, and elsewhere it is the path alone, so no request pays for a `stat`. A file that has gone missing is logged and skipped rather than taking the page down with a 500.

## Map styles

`map_style` names a MapLibre style JSON. Core's own styles live in `public/map-styles/<name>.json`; an extension ships its style as an engine asset at `app/assets/builds/map-styles/<name>.json`, which Propshaft picks up and serves at the same logical path. Mossley's is the worked example: it moved out of `public/map-styles/` into the theme engine and nothing else changed. `MapHelper#map_style_url` resolves the name from the request's theme (`Current.theme`), so it takes no arguments. It checks core's public directory first, then the asset pipeline, and falls back to `pink.json` if neither has it.

## Locale files

Rails automatically loads an engine's `config/locales/**/*.yml` into the I18n path. An extension's own strings live under its own namespace (`my_ext.*`) so they cannot collide with core.

To change a core string for sites on your theme only, add the same key under `theme_overrides.<theme name>` in one of the engine's locale files. Core's `t` helper (`PlaceCal::ThemeTranslation`, mixed into views, components and controllers) looks up `theme_overrides.<theme>.<key>` first for the current site's theme and falls back to `<key>`, so other sites are untouched and load order does not matter:

```yaml
# config/locales/overrides.en.yml
en:
  theme_overrides:
    my_ext:
      region_filter:
        all: Everywhere
```

Keep the overrides in their own file (`config/locales/overrides.en.yml` by convention) so it is obvious which strings the theme rewrites and which are its own.

Two things to know about which calls an override can reach. The key must be a String or a Symbol written out in full (`t("region_filter.all")` or `t(:"region_filter.all")`); a lazy key (`t(".all")`, which only the calling view can expand) is never overridable, so a core view using one has to be changed to an absolute key before a theme can rewrite it. And `scope:` is honoured: `t("all", scope: "region_filter")` looks up `theme_overrides.<theme>.region_filter.all`, the same place the absolute key does.

A blank value in core's own `config/locales/en.yml` is the idiom for a slot a theme may fill. Where a piece of copy is optional (a standfirst, a section name, a heading above a list, a prefix before an organiser name), core declares the key with an empty string rather than leaving it out. Core then renders nothing for it, because every one of those views skips a blank value, while the key still exists for a theme to override. It means core needs no conditional for theme-only copy, the theme needs no forked view, and the full set of fillable slots can be read off core's locale file. If you want a slot that does not exist yet, adding the blank key to core is a one-line change; see the note above the "local site listing pages" block in `config/locales/en.yml`.

Some core strings exist only as override slots: core ships them empty so nothing renders, and a theme fills them in. The listing pages carry one such slot, `<ns>.index.list_heading` (`partners.index.list_heading`, `events.index.list_heading`), which `Views::Base#list_heading` renders as an `h2` between the hero and the filters when it is not blank:

```yaml
en:
  theme_overrides:
    my_ext:
      partners:
        index:
          list_heading: All partners
```

## Stylesheet and CSS build

Themes are Tailwind plus CSS custom properties. Create a Tailwind source file in `app/tailwind/<ext>_tailwind.css` that imports the core theme variables and builds custom CSS:

```css
/* app/tailwind/my_ext_tailwind.css */
@import "tailwindcss/theme";
@import "tailwindcss/utilities";

:root {
	/* Override core theme tokens; see app/tailwind/public/_theme.css */
	--color-primary: #abc123;
	--color-background: #f5f1eb;
}

/* Component-level CSS (optional) */
.my-ext-card {
	@apply rounded-lg border border-gray-300;
}
```

Build the CSS with `@tailwindcss/cli`, pinned in the extension's own `package.json`, scanning only the extension's views:

```bash
tailwindcss -i ./app/tailwind/my_ext_tailwind.css \
  -o ./app/assets/builds/my_ext/theme.css \
  --content './app/views/my_ext/**/*.rb' \
  --minify
```

Commit the built `app/assets/builds/my_ext/theme.css` to the engine repo. The engine's CI should fail if it is stale. Propshaft picks up the engine's `app/assets/*` directories automatically and fingerprints the CSS for production.

## Installation and Gemfile

Each extension lives in its own git repo. Until a private installation repo exists, placecal.org's installation is the public PlaceCal repo itself, so an extension is listed in the public `Gemfile` under a clearly labelled `group :extensions do ... end` block, with a comment saying it is installation-specific and removable, pinned to a git tag in the extension repo:

```ruby
# Installation-specific extensions for placecal.org. Not part of core: a
# self-hosted PlaceCal can delete this block.
group :extensions do
  gem 'placecal-theme-transdimension',
      github: 'geeksforsocialchange/placecal-theme-transdimension',
      tag: 'v0.3.10'
  gem 'placecal-theme-mossley',
      github: 'geeksforsocialchange/placecal-theme-mossley',
      tag: 'v0.1.0'
end
```

Keep it a single block so removing it is one edit. Delete it rather than excluding the group: `config/application.rb` calls `Bundler.require(*Rails.groups, :extensions)`, so `BUNDLE_WITHOUT=extensions` leaves the gems uninstalled but still required and the app raises `LoadError` at boot. Deleting the block is the supported way to run without extensions, and sites already on an uninstalled theme keep working: they degrade to core's default styling and stay editable in admin.

The Dockerfile needs no Node build step for extensions because each engine ships its CSS prebuilt.

## Engine specs

An extension's test suite runs core's suite infrastructure: it boots core's Rails application with the engine loaded, and reuses core's spec support files, factories and fixtures. All of that is core's knowledge, so core ships it as `spec/extension_helper.rb` and the extension's `spec/rails_helper.rb` is four lines:

```ruby
# spec/rails_helper.rb (in the extension gem)
require "spec_helper"

PLACECAL_CORE = Pathname(ENV.fetch("PLACECAL_CORE_PATH", File.expand_path("../../PlaceCal", __dir__))).expand_path
require PLACECAL_CORE.join("spec/extension_helper").to_s
PlaceCal::ExtensionSpec.boot!(engine: "my_ext")
```

`boot!` takes the extension's module name in snake case, which is both `lib/<engine>.rb` and `<Engine>::Engine`. It requires core's `config/application`, then the engine (so its initializers run and the theme is registered), then core's `config/environment`; aborts if the environment is production; asserts that the engine Rails loaded is the checkout under test, naming the gem to put a `path:` entry on if it is not; globs core's `spec/support`, points FactoryBot at core's factories, checks for pending migrations, installs a raising I18n exception handler so a missing key fails at the point of use, and configures RSpec the way core does, including the time freeze core's shared factories assume.

Pass `system_specs: true` for an extension that has system specs, which adds the DatabaseCleaner strategy and the headless Chrome driver core uses:

```ruby
PlaceCal::ExtensionSpec.boot!(engine: "my_ext", system_specs: true)
```

It is opt-in so an extension without system specs does not need a browser in its CI. `root:` overrides the checkout the working-tree assertion expects; it defaults to the parent of the calling file's directory, which is the extension root when the caller is its `spec/rails_helper.rb`.

The signature is a compatibility surface: an extension pinned to a core tag may run its suite against core's `main`, so `boot!` keeps its keywords stable and core's own specs exercise it against the fixture engine.

### Running an extension's suite

The suite needs core's gem bundle, and core's `Gemfile` pins the extension to a released tag, so a development run needs a Gemfile that takes the extension from your checkout instead. Core's `bin/extension-dev-gemfile` writes one:

```bash
# from the core checkout
bin/extension-dev-gemfile placecal-theme-transdimension=../placecal-theme-transdimension

# from the extension checkout
PLACECAL_CORE_PATH=../PlaceCal \
  BUNDLE_GEMFILE=../PlaceCal/Gemfile.extensions-dev \
  RAILS_ENV=test bundle exec rspec
```

It takes `<gem>=<path>` pairs, and the paths are resolved as core sees them, from beside core's `Gemfile`. Every extension you do not name stays exactly as core pins it, so one boot still loads all of them: two engines registering two themes in one process is a property core has to keep working, and a dev Gemfile that dropped the sibling extension would hide a regression in it. The generated `Gemfile.extensions-dev` is local to the core checkout and gitignored there.

## Continuous integration

An extension's suite boots core, so its CI is core's CI plus the extension: check out both, point core's bundle at the extension checkout, build core's assets, then run the extension's own linting and specs. Core owns that as a reusable workflow, `.github/workflows/extension-test.yml`, and the extension's whole workflow is:

```yaml
name: Test

on:
  push:
    branches: ["main"]
    tags: ["v*"]
  pull_request:

jobs:
  test:
    uses: geeksforsocialchange/PlaceCal/.github/workflows/extension-test.yml@main
    with:
      engine: placecal-theme-transdimension
      module_dir: transdimension
      chrome: true
```

- `engine` is the gem name, as it appears in core's `Gemfile`. It is what the generated dev Gemfile swaps for a `path:` entry.
- `module_dir` is the directory under `lib/` holding `version.rb`, so the tag-versus-`VERSION` check can load it. It runs first, before any checkout or build, so a mistagged release fails in seconds.
- `placecal_ref` is the core ref to build against; it defaults to `main`. A reusable workflow is resolved at the ref the caller names, so `@main` couples the extension's CI to core's `main`: name the same ref in both places so the two move together.
- `chrome` installs headless Chrome, and defaults to `false`, so an extension with no system specs does not grow a browser it never uses.

Linting comes from core too. The extension's whole `.rubocop.yml` is `inherit_from: ../PlaceCal/config/rubocop/extension.yml`: the workflow checks core out at `./PlaceCal`, and locally the extension's RuboCop already runs with `BUNDLE_GEMFILE` pointed at a core checkout, so core is always beside it.

## Build and deploy

Core's Dockerfile is unchanged by extensions:

1. Each extension's CI fails if its committed CSS is stale (run the build before committing)
2. The Dockerfile runs core's `yarn build`, which only rebuilds core's CSS; extension CSS is already committed in the gem
3. Propshaft fingerprints all CSS (core and extension) during `assets:precompile`

Bumping the tag in the `group :extensions` block and running `bundle lock` is the whole deploy step for an extension change.
