const MAPLIBRE_CSS_ID = "maplibre-gl-css";

export function ensureMaplibreCss() {
	if (document.getElementById(MAPLIBRE_CSS_ID)) return;
	const link = document.createElement("link");
	link.id = MAPLIBRE_CSS_ID;
	link.rel = "stylesheet";
	// The CSS sits beside the pinned maplibre-gl JS, so both share one version
	link.href = new URL(
		"dist/maplibre-gl.css",
		import.meta.resolve("maplibre-gl"),
	).href;
	document.head.appendChild(link);
}
