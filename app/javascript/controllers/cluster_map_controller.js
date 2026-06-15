import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { markers: Array, styleUrl: String };

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
		this.map?.remove();
	}

	async _loadMap() {
		const [leafletMod] = await Promise.all([
			import("leaflet"),
			import("@maplibre/maplibre-gl-leaflet"),
			import("controllers/mixins/map_css").then((m) => m.ensureMaplibreCss()),
		]);
		window.L = leafletMod.default || leafletMod;
		await import("leaflet.markercluster");
		if (!this.element.isConnected) return;

		this.createMap();
	}

	createMap() {
		this.map = L.map(this.element, {
			scrollWheelZoom: false,
			zoomControl: false,
			maxZoom: 18,
			zoomSnap: 0.1,
		});

		L.control.zoom({ position: "topright" }).addTo(this.map);

		L.maplibreGL({
			style: this.styleUrlValue,
			attribution:
				'&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		}).addTo(this.map);

		const cluster = L.markerClusterGroup({
			showCoverageOnHover: false,
			maxClusterRadius: 40,
			spiderfyOnMaxZoom: true,
			iconCreateFunction: (c) => {
				const count = c.getChildCount();
				const size = count > 50 ? "lg" : count > 10 ? "md" : "sm";
				const dims = { sm: 36, md: 44, lg: 52 }[size];
				return L.divIcon({
					html: `<span>${count}</span>`,
					className: `cluster-marker cluster-${size}`,
					iconSize: L.point(dims, dims),
				});
			},
		});

		const icon = L.divIcon({
			className: "partner-dot",
			iconSize: [10, 10],
			iconAnchor: [5, 5],
		});

		for (const m of this.markersValue) {
			if (!m.lat || !m.lon) continue;
			const marker = L.marker([m.lat, m.lon], {
				icon,
				title: m.name || "Partner location",
			});
			if (m.name) {
				marker.bindPopup(m.url ? `<a href="${m.url}">${m.name}</a>` : m.name, {
					closeButton: false,
				});
			}
			cluster.addLayer(marker);
		}

		this.map.addLayer(cluster);

		if (this.markersValue.length > 0) {
			const bounds = cluster.getBounds();
			if (bounds.isValid()) {
				this.map.fitBounds(bounds, { padding: [10, 10] });
			}
		} else {
			this.map.setView([54.0, -2.0], 6);
		}

		this.map.invalidateSize(true);
	}
}
