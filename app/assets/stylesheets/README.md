# SCSS Stylesheets (Legacy)

These SCSS files are being incrementally migrated to Tailwind CSS.
When all files are converted, `dartsass-rails` can be removed entirely.

## Entry points

Compiled by `dartsass-rails` to `app/assets/builds/` for Propshaft to serve.
Configured in `config/initializers/dartsass.rb`.

| Entry point                  | Loads when                       | Purpose                                      |
| ---------------------------- | -------------------------------- | -------------------------------------------- |
| `application.scss`           | Every public page                | Globals, base styles, component styles       |
| `home.scss`                  | Default site only (placecal.org) | Homepage layout, cards, typography, patterns |
| `print.scss`                 | Print media                      | Print-specific overrides                     |
| `themes/blue.scss`           | Partner sites with blue theme    | CSS custom property overrides                |
| `themes/green.scss`          | Partner sites with green theme   | CSS custom property overrides                |
| `themes/orange.scss`         | Partner sites with orange theme  | CSS custom property overrides                |
| `themes/pink.scss`           | Partner sites with pink theme    | CSS custom property overrides                |
| `themes/custom/mossley.scss` | Mossley partner site             | Full custom theme (colours, layout, images)  |

## How stylesheets are loaded

The public layout (`app/views/layouts/application.rb`) loads:

1. `application.css` -- always
2. `public_tailwind.css` -- always (Tailwind, built by yarn not dartsass)
3. `Site#stylesheet_link` -- per-site: returns `"home"` for the default site, `"themes/{theme}"` for standard themes, or `"themes/custom/{slug}"` for custom themes
4. `print.css` -- print media only

## Directory structure

```
application.scss          # Main entry: globals + components
home.scss                 # Default site entry
print.scss                # Print entry
globals.scss              # Shared: base styles, vendor, regions, articles
variables_mixins.scss     # Shared: variables, mixins, breakpoints, flexbox
_image_url_compat.scss    # Propshaft compat shim for image-url()
base/                     # Reset, typography, layout, grid, map, buttons, icons, images
components/               # Navigation, events, filters, details, opening times, paginator
home/                     # Default site: cards, forms, grid, layout, patterns, typography
home/pages/               # Default site page-specific: index, impact, our_story
modules/                  # Breakpoints, flexbox mixins, placeholders
regions/                  # Region-specific styles (default)
themes/                   # Partner colour themes (blue, green, orange, pink)
themes/custom/            # Full custom themes (mossley)
variables/                # Colour, typography, font variables
vendor/                   # Local copies of vendor CSS (leaflet)
articles/                 # Article index + show styles
```
