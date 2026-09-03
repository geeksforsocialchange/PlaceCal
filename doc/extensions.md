# Writing Extensions

PlaceCal extensions are Rails engines that plug into the core application without modifying it. An extension registers a theme: a set of stylesheets, views, components, locale files, and configuration that customize PlaceCal's appearance and behaviour for a specific site or installation.

## The extension contract

If a second partnership could want it, it is a core feature and gets built generically. If only this site wants it, it is views, CSS, assets and copy in an extension. Extensions contain no models, no migrations, no business logic.

Extensions are Rails engines generated with `rails plugin new --full` (NOT `--mountable`: the engine must not isolate its namespace or routes, it plugs into the host app) and trimmed to the layout below.

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

An extension normally has no controllers: core's controllers serve every page and the extension supplies views, components and copy. An engine _may_ draw routes in its own `config/routes.rb` (they load after core's `config/routes.rb`, so they win over core's `/:slug` site-page catch-all, which is appended last by `config/initializers/site_page_routes.rb`), but a theme that needs new routes is usually a sign the feature belongs in core. Core's fixture engine under `spec/` has both, for testing.

## Phlex namespaces

Create a module namespace in `lib/<ext>.rb` and register Phlex kits in the engine initializer:

```ruby
# lib/<ext>.rb
module MyExt
  module Views; end
  module Components
    extend Phlex::Kit
  end
end
require_relative "my_ext/engine"

# lib/<ext>/engine.rb
module MyExt
  class Engine < ::Rails::Engine
    initializer "my_ext.phlex_namespaces", before: :set_autoload_paths do
      Rails.autoloaders.main.push_dir(
        root.join("app/views/my_ext"),
        namespace: MyExt::Views
      )
      Rails.autoloaders.main.push_dir(
        root.join("app/components/my_ext"),
        namespace: MyExt::Components
      )
    end
  end
end
```

Views inherit `Views::Base` to get Rails helpers, `t()` translations, and the core `Components` kit. Components inherit `Components::Base`.

## Theme registration

The engine registers a theme during initialization (before core's `config/initializers` run):

```ruby
initializer "my_ext.register_theme" do
  PlaceCal::Extensions.register_theme(:my_ext) do |theme|
    theme.stylesheet    "my_ext/theme"
    theme.homepage_view "MyExt::Views::Home"
    theme.map_style     "my_ext"
    theme.head          "MyExt::Components::Head"
    theme.footer        "MyExt::Components::Footer"
    theme.theme_color   "#f19089"
    theme.background_color "#040f39"
    theme.icons         favicon_32: "my_ext/favicons/favicon-32x32.png",
                        favicon_16: "my_ext/favicons/favicon-16x16.png",
                        apple_touch_icon: "my_ext/favicons/apple-touch-icon.png",
                        mask_icon: "my_ext/favicons/safari-pinned-tab.svg",
                        icon_192: "my_ext/favicons/android-chrome-192x192.png",
                        icon_512: "my_ext/favicons/android-chrome-512x512.png"
    theme.mask_icon_color "#FF7AA7"
    theme.og_image      "my_ext/og.png", width: 1200, height: 675
    theme.nav_cta       "my_ext.nav.donate", "https://example.org/donate"
    theme.nav_join      false
    theme.menu_label    true
    theme.event_filter_style :day_strip
  end
end
```

Every setting is optional, and the full list is defined in `lib/placecal/theme.rb`:

| Setting              | Value                                                                                              | Default              | What it does                                                                                                                                                                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `stylesheet`         | asset logical path without the extension, or a block taking the Site                               | none                 | Linked in `<head>` after core's stylesheets. Skipped with an error in the log if the asset does not resolve, so a stale build cannot take the site down.                                                                                            |
| `homepage_view`      | Phlex view class name (String)                                                                     | core's site homepage | Renders the site's homepage.                                                                                                                                                                                                                        |
| `map_style`          | MapLibre style name, or a block taking the Site                                                    | `pink`               | See "Map styles" below.                                                                                                                                                                                                                             |
| `head`               | Phlex component class name                                                                         | none                 | Rendered inside `<head>`, for fonts, meta tags and the like.                                                                                                                                                                                        |
| `footer`             | Phlex component class name                                                                         | core's footer        | Replaces core's site footer. Constructed with `new(site:, navigation:)`.                                                                                                                                                                            |
| `theme_color`        | hex colour, e.g. `"#f19089"`                                                                       | none                 | `theme-color` value in the web manifest, and the `<meta name="theme-color">` on the site's pages.                                                                                                                                                   |
| `background_color`   | hex colour, e.g. `"#040f39"`                                                                       | `theme_color`        | Splash `background_color` in the web manifest, for themes whose splash differs from their chrome colour.                                                                                                                                            |
| `icons`              | keyword paths: `favicon_32`, `favicon_16`, `apple_touch_icon`, `mask_icon`, `icon_192`, `icon_512` | none                 | The theme's own favicons, touch icon, Safari mask icon and manifest icons. Any icon set replaces core's `favicon.png` and `apple-touch-icon.png` in `<head>`; `icon_192`/`icon_512` replace the manifest icons. Unknown keys raise `ArgumentError`. |
| `mask_icon_color`    | hex colour, e.g. `"#FF7AA7"`                                                                       | none                 | `color` attribute of `<link rel="mask-icon">`.                                                                                                                                                                                                      |
| `og_image`           | asset logical path plus `width:` and `height:`                                                     | none                 | A static Open Graph share image for the theme's sites, in place of core's generated share card.                                                                                                                                                     |
| `nav_cta`            | locale key and URL                                                                                 | none                 | A call-to-action link (for example Donate) rendered as the last item in the site nav.                                                                                                                                                               |
| `nav_join`           | boolean                                                                                            | `true`               | Whether the derived nav includes the Join link when the site takes enquiries. Set `false` when the theme's own footer carries it.                                                                                                                   |
| `event_filter_style` | `:date_picker` or `:day_strip`                                                                     | `:date_picker`       | Which date control the events filter renders.                                                                                                                                                                                                       |
| `menu_label`         | boolean                                                                                            | `false`              | Whether the mobile menu toggle shows a "Menu" text label next to the icon.                                                                                                                                                                          |

Class names are given as strings and resolved lazily, so registration can run before autoloading is ready; a name that no longer resolves is logged and core's default renders instead.

`stylesheet` and `map_style` may receive a block that gets the Site, for lookups that depend on the record (core's legacy `custom` theme resolves by site slug that way).

## Map styles

`map_style` names a MapLibre style JSON. Core's own styles live in `public/map-styles/<name>.json`; an extension ships its style as an engine asset at `app/assets/builds/map-styles/<name>.json`, which Propshaft picks up and serves at the same logical path. `MapHelper#style_url_for_site` checks core's public directory first, then the asset pipeline, and falls back to `pink.json` if neither has it.

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

Some core strings exist only as override slots: core ships them empty so nothing renders, and a theme fills them in. The listing pages carry one such slot, `<ns>.index.list_heading` (`partners.index.list_heading`, `events.index.list_heading`), which `Components::ListHeading` renders as an `h2` between the hero and the filters when it is not blank:

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
      tag: 'v0.1.0'
end
```

Keep it a single block so removing it is one edit. The Dockerfile needs no Node build step for extensions because each engine ships its CSS prebuilt.

## Engine specs

An extension's own test suite requires core's Rails environment. In `spec/rails_helper.rb`, boot core by requiring its `config/application` and `config/environment` (using an env var for the core path, defaulting to `../PlaceCal`):

```ruby
# spec/rails_helper.rb (in the extension gem)
require 'spec_helper'

# Bootstrap core's Rails app
PLACECAL_CORE = ENV.fetch('PLACECAL_CORE_PATH', '../PlaceCal')
require File.expand_path('config/application', PLACECAL_CORE)
require 'rspec/rails'

# Require the engine (this file's directory goes on the load path)
require File.expand_path('../../lib/<ext>', __FILE__)

# Finish loading core's environment
Rails.application.initialize! unless Rails.application.initialized?
```

Require the extension before `Rails.application.initialize!` so that its engine initializers run and register the theme. The extension's `spec/` directory is part of the engine repo and may have factories, fixtures and helper modules shared with core's tests.

## Build and deploy

Core's Dockerfile is unchanged by extensions:

1. Each extension's CI fails if its committed CSS is stale (run the build before committing)
2. The Dockerfile runs core's `yarn build`, which only rebuilds core's CSS; extension CSS is already committed in the gem
3. Propshaft fingerprints all CSS (core and extension) during `assets:precompile`

Bumping the tag in the `group :extensions` block and running `bundle lock` is the whole deploy step for an extension change.
