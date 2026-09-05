# Mapbox to OpenFreeMap Migration

- Author: @kimadactyl
- Date: 2026-01-27
- Status: **Implemented**

## Context and Problem Statement

PlaceCal has historically used Mapbox for interactive maps on the public website. While Mapbox provides excellent cartography, it has several drawbacks:

- Requires API key management
- Has usage-based costs that scale with traffic
- Proprietary service with potential availability concerns
- No offline/self-hosted option

We needed a free, open-source alternative that maintains the PlaceCal brand styling while eliminating costs and API key dependencies.

## Decision Drivers

- Remove recurring costs and API key requirements
- Use open-source, self-hosted-capable technology
- Maintain PlaceCal brand colors and visual identity
- Ensure compatibility with existing Leaflet-based implementation
- Support multiple color themes for different sites (pink, blue, green, orange)

## Decision Outcome

Migrate from Mapbox to **OpenFreeMap** with **MapLibre GL** as the rendering library.

### Technology Stack

| Component         | Old               | New                              |
| ----------------- | ----------------- | -------------------------------- |
| Tile Provider     | Mapbox            | OpenFreeMap                      |
| Rendering Library | Mapbox GL JS      | MapLibre GL JS                   |
| Style Format      | Mapbox Style JSON | MapLibre Style JSON (compatible) |

### Implementation Details

**Tile Source:**

```
https://tiles.openfreemap.org/planet
```

**Font Glyphs:**

```
https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf
```

**Sprites:**

```
https://tiles.openfreemap.org/sprites/ofm_f384/ofm
```

### Style Files

Core's map styles are stored in `public/map-styles/`, one per core theme:

| File          | Usage               | Parks Color        | Water Color              |
| ------------- | ------------------- | ------------------ | ------------------------ |
| `pink.json`   | Default theme       | `#AFCF5A` (green)  | `#86CED6` (teal)         |
| `blue.json`   | Blue-themed sites   | `#28a9e1` (blue)   | `#93d1e2` (light blue)   |
| `green.json`  | Green-themed sites  | `#AFCF5A` (green)  | `#86CED6` (teal)         |
| `orange.json` | Orange-themed sites | `#e87d1e` (orange) | `#f4b183` (light orange) |

Which one a request gets is the theme's decision, not the site's: `MapHelper#map_style_url` reads `Current.theme.map_style_name` (`PlaceCal::Theme#map_style`, see `doc/extensions.md`) and falls back to `pink` for the nationwide directory and for a site whose theme nothing registers. An extension theme names its own style and ships it as an asset rather than in `public/`, so the helper looks in `public/map-styles/` first and then resolves `map-styles/<name>.json` through the asset pipeline. `mossley.json` used to live here; Mossley is an extension now and the file went with it.

### PlaceCal Brand Colors (from original Mapbox exports)

| Element           | Hex       | Description    |
| ----------------- | --------- | -------------- |
| Background        | `#FFFCF0` | Cream          |
| Parks (default)   | `#AFCF5A` | PlaceCal green |
| Water (default)   | `#86CED6` | Teal           |
| Roads (main)      | `#F2D8BA` | Tan            |
| Roads (secondary) | `#C7B299` | Light brown    |
| Borders           | `#998675` | Brown          |
| Text              | `#5B4E46` | Dark brown     |
| Rail/Accent       | `#9469AE` | Purple         |

## Positive Consequences

- Zero ongoing costs for map tiles
- No API key management required
- Fully open-source stack (OpenFreeMap + MapLibre GL)
- Can self-host tiles if needed in future
- Maintains PlaceCal brand identity
- Compatible with existing Stimulus controller architecture

## Negative Consequences

- Tile quality/detail may differ from Mapbox in some areas
- Dependent on OpenFreeMap service availability (though tiles can be cached/self-hosted)
- Style customization requires manual JSON editing rather than Mapbox Studio

## References

- [OpenFreeMap](https://openfreemap.org/) - Free map tile provider
- [MapLibre GL JS](https://maplibre.org/) - Open-source map rendering library
- Original Mapbox styles exported to `~/Downloads/placecal-mapbox-style/` and `~/Downloads/placecal-moston-style/`
- Implementation commit: 5198b180
