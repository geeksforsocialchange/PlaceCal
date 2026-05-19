const MAPLIBRE_CSS_ID = "maplibre-gl-css";

export function ensureMaplibreCss() {
	if (document.getElementById(MAPLIBRE_CSS_ID)) return;
	const link = document.createElement("link");
	link.id = MAPLIBRE_CSS_ID;
	link.rel = "stylesheet";
	link.href = "/vendor/maplibre-gl.css";
	document.head.appendChild(link);
}
