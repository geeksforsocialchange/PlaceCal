import { Controller } from "@hotwired/stimulus";
import "leaflet";
import "@maplibre/maplibre-gl-leaflet";

// Connects to data-controller="leaflet"
// Its important to use single quotes in the template when declaring the args values
// data-leaflet-args-value='<%= args_for_map(points, site, local_assigns[:style], local_assigns[:compact]) %>'
// If not you will get strange unicode values which will break parsing
export default class extends Controller {
	static values = { args: Object };
	// {center, iconUrl, markers, shadowUrl, styleClass, styleUrl, zoom}

	connect() {
		this.element.classList.add("map");
		if (this.argsValue.styleClass?.length)
			this.element.classList.add(...this.argsValue.styleClass);
		this.createMap();
	}

	disconnect() {
		this.element.classList.remove("map");
		if (this.argsValue.styleClass?.length)
			this.element.classList.remove(...this.argsValue.styleClass);
		this.map.remove();
	}

	createMap() {
		this.map = L.map(this.element);
		this.map.scrollWheelZoom.disable();

		// Use MapLibre GL for vector tile rendering with custom themed styles
		L.maplibreGL({
			style: this.argsValue.styleUrl,
			attribution:
				'&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		}).addTo(this.map);

		this.map.invalidateSize(true);

		const mapIcon = L.icon({
			iconUrl: this.argsValue.iconUrl,
			shadowUrl: this.argsValue.shadowUrl,

			iconSize: [46, 43], // size of the icon
			shadowSize: [46, 43], // size of the shadow

			// [x,y] offsets. x is left edge to tip of point, y is icon height
			iconAnchor: [17, 43],
			shadowAnchor: [17, 43],

			// offset relative to tip of iconAnchor's point. so x=0, y=-iconSize.y
			popupAnchor: [0, -43],
		});

		this.map.setView(this.argsValue.center, this.argsValue.zoom);

		const markers = this.argsValue.markers.map((m) => {
			const mapMarker = L.marker(m.position, { icon: mapIcon });
			mapMarker.addTo(this.map);
			mapMarker.bindPopup(m.anchor, { permanent: true, closeButton: false });
			return mapMarker;
		});

		const markerGroup = L.featureGroup(markers);
		if (markers.length === 1) {
			// Single marker: use setView to keep zoom level
			this.map.setView(this.argsValue.center, this.argsValue.zoom);
		} else {
			// Multiple markers: fit bounds to show all markers
			const bounds = markerGroup.getBounds();
			if (
				bounds.getNorth() === bounds.getSouth() &&
				bounds.getEast() === bounds.getWest()
			) {
				// All markers at same position: fitBounds would fail on zero-area box
				this.map.setView(bounds.getCenter(), this.argsValue.zoom);
			} else {
				// Extend bounds slightly south to account for marker icon height
				const south = bounds.getSouth();
				const offset = (bounds.getNorth() - south) * 0.08; // 8% extra at bottom
				bounds.extend([south - offset, bounds.getWest()]);
				this.map.fitBounds(bounds);
			}
		}
	}
}
