import { Controller } from "@hotwired/stimulus";
import "leaflet";

// Connects to data-controller="leaflet"
// Its important to use single quotes in the template when declaring the args values
// data-leaflet-args-value='<%= args_for_map(points, site, local_assigns[:style], local_assigns[:compact]) %>'
// If not you will get strange unicode values which will break parsing
export default class extends Controller {
	static values = { args: Object };
	// {center, iconUrl, markers, shadowUrl, styleClass, tilesetUrl, zoom}

	map;

	connect() {
		this.element.classList.add("map");
		this.createMap();
	}

	disconnect() {
		this.element.classList.remove("map");
		this.argsValue.styleClass.forEach((className) => {
			this.element.classList.remove(className);
		});
		this.map.remove();
	}

	createMap() {
		this.map = L.map(this.element);
		this.argsValue.styleClass.forEach((className) => {
			this.element.classList.add(className);
		});
		this.map.scrollWheelZoom.disable();
		L.tileLayer(this.argsValue.tilesetUrl, {
			attribution: "PlaceCal",
			maxZoom: 18,
		}).addTo(this.map);
		this.map.invalidateSize(true);

		const mapIcon = L.icon({
			iconUrl: this.argsValue.iconUrl,
			shadowUrl: this.argsValue.shadowUrl,

			iconSize: [46, 43], // size of the icon
			shadowSize: [46, 43], // size of the shadow
			iconAnchor: [17, 0], // point of the icon which will correspond to marker's location
			shadowAnchor: [17, 0], // the same for the shadow
			popupAnchor: [0, 0], // point from which the popup should open relative to the iconAnchor
		});

		this.map.setView(this.argsValue.center, this.argsValue.zoom);

		const markers = this.argsValue.markers.map((m) => {
			const mapMarker = L.marker(m.position, { icon: mapIcon });
			mapMarker.addTo(this.map);
			mapMarker.bindPopup(m.anchor, { permanent: true, closeButton: false });
			return mapMarker;
		});

		const markerGroup = L.featureGroup(markers);
		this.map.fitBounds(markerGroup.getBounds(), {
			maxZoom: this.argsValue.zoom,
		});
	}
}
