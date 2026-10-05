# Map Styles

These MapLibre GL style JSON files must live in `public/` because they are
fetched client-side by MapLibre via URL. They cannot be served through the
Rails asset pipeline.

See `doc/adr/0011-mapbox-to-openfreemap-migration.md` for migration details.

## Files

One per core theme. An extension theme ships its own style as an asset in its
engine rather than adding a file here.

- `pink.json` - Default theme (green parks, teal water)
- `green.json` - Green theme (same as pink)
- `blue.json` - Blue theme (blue parks, light blue water)
- `orange.json` - Orange theme (orange parks, light orange water)

## Usage

`MapHelper#map_style_url` asks the request's theme for its style name
(`Current.theme.map_style_name`, set by `PlaceCal::Theme#map_style`), looks for
that name in this directory, then falls back to resolving
`map-styles/<name>.json` through the asset pipeline, which is where an
extension's own style lives. The nationwide directory, and any site whose theme
nothing registers, gets `pink.json`.
