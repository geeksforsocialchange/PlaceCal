# Writing Extensions

An extension is a Rails engine that registers a theme for one site or installation: stylesheets, views, components, locale strings and settings. Core loads every installed extension at once; today that is the Trans Dimension and Marvellous Mossley.

## The contract

An extension contains views, components, assets, locales, content and rake tasks. It has no models, migrations, controllers, routes or business logic. A theme that needs a new route is a feature for core.

Generate one with `rails plugin new --full` (not `--mountable`: it must not isolate its namespace).

## Trust

An extension runs in the app's process with full access to the database, credentials and network. Treat it as a code dependency, not content:

1. Only a maintainer adds or bumps one, through a PR to core's `Gemfile`. There is no runtime install.
2. It is pinned by git tag, and `Gemfile.lock` records the commit, so a retagged release shows up in the diff.
3. It lives in a GFSC repo with branch protection on its default branch.
4. It stays inside the contract above. Review checks this, and `bin/check-extension-tree` fails CI if an extension ships anything under `app/models`, `app/controllers`, `db/`, `config/routes.rb`, `config/initializers`, or Ruby in `lib/` beyond its entry point, engine and version files.

A theme that cannot run code at all needs a different mechanism ([#3489](https://github.com/geeksforsocialchange/PlaceCal/issues/3489)).

## Layout

```
<ext>/
  lib/<ext>.rb             # namespace, loads the engine
  lib/<ext>/engine.rb      # theme registration
  lib/<ext>/version.rb
  app/views/<ext>/         # Phlex views, autoloaded as <Ext>::Views
  app/components/<ext>/    # Phlex components, autoloaded as <Ext>::Components
  app/tailwind/            # CSS source
  app/assets/builds/<ext>/ # built CSS, committed
  config/locales/          # loaded by Rails automatically
  content/                 # markdown for content pages
```

## The engine

```ruby
# lib/my_ext.rb
module MyExt
  module Views; end

  module Components
    extend Phlex::Kit
  end
end

# Fails by name on a core too old to have PlaceCal::Extension.
abort('placecal-theme-my-ext needs a newer PlaceCal; see "Minimum core" in README.md.') unless defined?(PlaceCal::Extension)

require_relative "my_ext/version"
require_relative "my_ext/engine"

# lib/my_ext/engine.rb
module MyExt
  class Engine < ::Rails::Engine
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

`include PlaceCal::Extension` autoloads `app/views/my_ext` as `MyExt::Views` and `app/components/my_ext` as `MyExt::Components`, and registers the theme at boot.

`required_settings` lists every theme setting the engine uses. On a core that lacks one, boot raises `PlaceCal::Extension::UnsupportedHost` naming it. It checks names only, not signatures, so every extension should also have a contract spec that calls `MyExt::Engine.configure_theme(PlaceCal::Theme.new(:throwaway))`: that makes the same calls against a real `PlaceCal::Theme`, so a changed signature fails in the extension's CI rather than at boot.

State the core version the theme needs in a "Minimum core" section of its README.

## Theme settings

Views inherit `Views::Base` (Rails helpers, `t()`, core's component kit) and components inherit `Components::Base`. Every setting is optional; `lib/placecal/theme.rb` defines them. Class names are strings, resolved lazily; one that no longer resolves is logged and core's default renders.

| Setting                      | Value                                                                                                  | Default               | Effect                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------------ | --------------------- | -------------------------------------------------------------------------- |
| `stylesheet`                 | asset path                                                                                             | none                  | Linked after core's CSS. Skipped, with a log error, if it doesn't resolve. |
| `homepage_view`              | view class                                                                                             | core's                | Renders the homepage.                                                      |
| `map_style`                  | style name                                                                                             | `pink`                | See Map styles.                                                            |
| `head`                       | component class                                                                                        | none                  | Rendered in `<head>`.                                                      |
| `font_stylesheet`            | URL, `preconnect:` origins                                                                             | none                  | Webfont stylesheet with preconnect and preload.                            |
| `footer`                     | component class                                                                                        | core's                | Replaces the footer; built with `new(site:, navigation:)`.                 |
| `theme_color`                | hex                                                                                                    | none                  | Manifest and `<meta name="theme-color">`.                                  |
| `background_color`           | hex                                                                                                    | `theme_color`         | Manifest splash colour.                                                    |
| `icons`                      | `favicon_32`, `favicon_16`, `apple_touch_icon`, `mask_icon`, `mask_icon_color`, `icon_192`, `icon_512` | none                  | Replaces core's favicons and manifest icons.                               |
| `og_image`                   | asset path, `width:`, `height:`                                                                        | none                  | Static share image instead of the generated card.                          |
| `nav_cta`                    | locale key, URL                                                                                        | none                  | Last link in the nav, e.g. Donate.                                         |
| `nav_join`                   | boolean                                                                                                | `true`                | Join link in the nav when the site takes enquiries.                        |
| `nav_region_filter`          | boolean                                                                                                | `false`               | Region control in the nav, if the site has two or more Partnership tags.   |
| `event_neighbourhood_filter` | boolean                                                                                                | `true`                | Neighbourhood filter on the events listing. Off skips its count query.     |
| `events_default_period`      | `'future'`, `'week'`, `'day'`                                                                          | core picks by density | Events listing period when none is requested.                              |
| `event_filter_style`         | `:date_picker`, `:day_strip`, `:day_strip_with_date_picker`                                            | `:date_picker`        | Date control on the events filter.                                         |
| `menu_label`                 | boolean                                                                                                | `false`               | "Menu" text beside the mobile menu icon.                                   |
| `page`                       | slug, view class, `nav_label_key:`                                                                     | none                  | A content page at `/<slug>`; repeatable.                                   |

## Theme pages

Core stores no page content. A theme serves its own pages:

```ruby
theme.page "about", "MyExt::Views::About", nav_label_key: "my_ext.nav.about"
theme.page "privacy", "MyExt::Views::Privacy"
```

- Served at `/<slug>` on every site using the theme, built with `new(site:)`, and listed in the sitemap.
- With `nav_label_key`, the page is linked in the nav and footer after News.
- Slugs are lowercase letters, numbers and hyphens. A slug a core route already owns (`events`, `partners`, `news`) is unreachable. `privacy` is the exception: core's `/privacy` uses the theme's page when there is one.

### Markdown content pages

```ruby
class MyExt::Views::About < Views::ThemeContentPage
  content_root MyExt::Engine.root.join("content")
  slug         "about"
  title        "my_ext.about.title"
  description  "my_ext.site.description"

  markdown "about/main.md"
  markdown "about/accessibility.md", heading: "my_ext.about.accessibility", heading_level: :h3
end
```

This renders a `page page--<slug>` wrapper, an `h1`, and each file in a `.markdown-content` column under its heading (`h2` unless `heading_level:` says `:h3` to `:h6`). Settings are inherited, so several pages can share a base class. Override `page_body` for more than headings and files, or `page_content` to drop the `.markdown-content` column.

Markdown is sanitised to an allow-list, cached per file, and a missing file is logged and skipped.

## Map styles

`map_style` names a MapLibre style JSON. An extension ships it at `app/assets/builds/map-styles/<name>.json`; core's live in `public/map-styles/`. Unknown names fall back to `pink`.

## Locales

An extension's own strings live under its own namespace (`my_ext.*`).

To change a core string for your theme only, put the same key under `theme_overrides.<theme>` in `config/locales/overrides.en.yml`:

```yaml
en:
  theme_overrides:
    my_ext:
      region_filter:
        all: Everywhere
```

Overrides work for absolute keys (`t("region_filter.all")`, including with `scope:`), not lazy ones (`t(".all")`).

Core declares optional copy (a standfirst, a list heading, a prefix) as an empty string in `config/locales/en.yml`. Core renders nothing for it, and a theme fills it with an override. To add a new slot, add the blank key to core.

## CSS

Themes are Tailwind plus CSS custom properties that override core's tokens (`app/tailwind/public/_theme.css`). Build with `@tailwindcss/cli`, pinned in the extension's `package.json`:

```bash
tailwindcss -i ./app/tailwind/theme.css -o ./app/assets/builds/my_ext/theme.css --minify
```

Commit the built CSS; CI fails if it is stale. Propshaft serves and fingerprints it, so core's Dockerfile needs no extension build step.

## Installation and Gemfile

placecal.org's extensions are listed in core's `Gemfile` in one removable block, pinned by tag:

```ruby
group :extensions do
  gem 'placecal-theme-mossley', github: 'geeksforsocialchange/placecal-theme-mossley', tag: 'vX.Y.Z'
end
```

A self-hosted PlaceCal deletes the block to run without extensions. Excluding the group with `BUNDLE_WITHOUT` does not work, because `config/application.rb` requires it. Sites on a removed theme fall back to core's styling.

## Engine specs

An extension's suite boots core with the engine loaded and uses core's support files and factories. Its `spec/rails_helper.rb`:

```ruby
require "spec_helper"

PLACECAL_CORE = Pathname(ENV.fetch("PLACECAL_CORE_PATH", File.expand_path("../../PlaceCal", __dir__))).expand_path
require PLACECAL_CORE.join("spec/extension_helper").to_s
PlaceCal::ExtensionSpec.boot!(engine: "my_ext")
```

Pass `system_specs: true` to `boot!` for headless Chrome system specs.

### Running an extension's suite

To run it locally, generate a Gemfile in core that loads the extension from your checkout, then run from the extension:

```bash
# in core
bin/extension-dev-gemfile placecal-theme-my-ext=../placecal-theme-my-ext

# in the extension
PLACECAL_CORE_PATH=../PlaceCal BUNDLE_GEMFILE=../PlaceCal/Gemfile.extensions-dev RAILS_ENV=test bundle exec rspec
```

Other extensions stay at core's pinned versions, so the run still loads them all. The generated Gemfile is gitignored.

## Continuous integration

Core's reusable workflow builds core and runs the extension's RuboCop and specs. The extension's `.github/workflows/test.yml`:

```yaml
on:
  push:
    branches: ["main"]
    tags: ["v*"]
  pull_request:

jobs:
  test:
    uses: geeksforsocialchange/PlaceCal/.github/workflows/extension-test.yml@main
    with:
      engine: placecal-theme-my-ext # gem name in core's Gemfile
      module_dir: my_ext # lib/<dir>/version.rb, checked against the tag
      chrome: true # only for system specs
```

Its `.rubocop.yml` is `inherit_from: ../PlaceCal/config/rubocop/extension.yml`.

## Releasing an extension

1. Bump `lib/<ext>/version.rb` and `package.json` together in the PR. A PR that doesn't bump them releases nothing.
2. On merge, once main's tests pass, the `release` job in `test.yml` tags `v<version>` and publishes a GitHub release. The commits between tags are the changelog.
3. Core's `extension-pins.yml` workflow runs hourly, or from the Actions tab, and opens "Pin <gem> at v<version>" with the Gemfile and lockfile change. Merging it deploys to staging. `DRY_RUN=1 bin/extension-pin-bumps` shows what it would do.

Pin PRs only run CI if core has an `EXTENSION_PIN_TOKEN` secret (a token with contents and pull-request write); otherwise close and reopen the PR to start it.

To pin by hand:

```bash
rake "placecal:extension:bump[placecal-theme-mossley,0.1.2]"
```

Commit `Gemfile` and `Gemfile.lock` together.
