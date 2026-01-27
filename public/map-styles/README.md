# Map Styles

These MapLibre GL style JSON files must live in `public/` because they are
fetched client-side by MapLibre via URL. They cannot be served through the
Rails asset pipeline.

See `doc/adr/0011-mapbox-to-openfreemap-migration.md` for migration details.

## Files

- `pink.json` - Default theme (green parks, teal water)
- `green.json` - Green theme (same as pink)
- `blue.json` - Blue theme for Moston (blue parks, light blue water)
- `orange.json` - Orange theme (orange parks, light orange water)

## Usage

Styles are selected based on site configuration in `app/helpers/map_helper.rb`.
