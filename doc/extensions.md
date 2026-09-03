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

The engine's `app/controllers` and `config/routes.rb` exist only in core's fixture engine (for testing); real extensions have neither.

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
    theme.stylesheet    "my_ext/theme"           # logical path, see CSS build below
    theme.homepage_view "MyExt::Views::Home"     # Phlex view class name
    theme.map_style     "my_ext"                 # name of public/map-styles/<name>.json
    theme.head          "MyExt::Components::Head" # Phlex component rendered in <head>
    theme.event_filter_style :day_strip          # :date_picker (default) or :day_strip
  end
end
```

All settings are optional. `stylesheet` and `map_style` may receive a block that gets the Site, for lookups that depend on the record (core's legacy `custom` theme resolves by site slug that way).

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
