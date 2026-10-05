import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { args: Object };

	connect() {
		if ("requestIdleCallback" in window) {
			this._idleId = requestIdleCallback(() => this._loadMap(), {
				timeout: 4000,
			});
		} else {
			this._timerId = setTimeout(() => this._loadMap(), 200);
		}
	}

	disconnect() {
		if (this._idleId) cancelIdleCallback(this._idleId);
		if (this._timerId) clearTimeout(this._timerId);
		this.element.classList.remove("map");
		if (this.argsValue.styleClass?.length)
			this.element.classList.remove(...this.argsValue.styleClass);
		this.map?.remove();
	}

	async _loadMap() {
		const [, , { ensureMaplibreCss }] = await Promise.all([
			import("leaflet"),
			import("@maplibre/maplibre-gl-leaflet"),
			import("controllers/mixins/map_css"),
		]);
		if (!this.element.isConnected) return;

		ensureMaplibreCss();
		this.element.classList.add("map");
		if (this.argsValue.styleClass?.length)
			this.element.classList.add(...this.argsValue.styleClass);
		this.createMap();
	}

	createMap() {
		this.map = L.map(this.element);
		this.map.scrollWheelZoom.disable();

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
			this.map.setView(this.argsValue.center, this.argsValue.zoom);
		} else {
			const bounds = markerGroup.getBounds();
			if (
				bounds.getNorth() === bounds.getSouth() &&
				bounds.getEast() === bounds.getWest()
			) {
				this.map.setView(bounds.getCenter(), this.argsValue.zoom);
			} else {
				const south = bounds.getSouth();
				const offset = (bounds.getNorth() - south) * 0.08;
				bounds.extend([south - offset, bounds.getWest()]);
				this.map.fitBounds(bounds);
			}
		}
	}
}
