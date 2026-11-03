import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { markers: Array, styleUrl: String, labels: Object };

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

		L.control
			.zoom({
				position: "topright",
				zoomInTitle: this.labelsValue.zoomIn,
				zoomOutTitle: this.labelsValue.zoomOut,
			})
			.addTo(this.map);
		const plural = new Intl.PluralRules(document.documentElement.lang);

		L.maplibreGL({
			style: this.styleUrlValue,
			attribution:
				'&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		})
			// MapLibre names its canvas "Map" too; the map's own container is the one landmark.
			.on("add", (e) =>
				e.target.getContainer().setAttribute("aria-hidden", "true"),
			)
			.addTo(this.map);

		const cluster = L.markerClusterGroup({
			showCoverageOnHover: false,
			maxClusterRadius: 40,
			spiderfyOnMaxZoom: true,
			iconCreateFunction: (c) => {
				const count = c.getChildCount();
				const size = count > 50 ? "lg" : count > 10 ? "md" : "sm";
				const dims = { sm: 36, md: 44, lg: 52 }[size];
				const label = (
					plural.select(count) === "one"
						? this.labelsValue.clusterOne
						: this.labelsValue.clusterOther
				).replace("%{count}", count);
				return L.divIcon({
					html: `<span aria-hidden="true">${count}</span><span class="sr-only">${label}</span>`,
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
				title: m.name ?? "",
				keyboard: !!m.name,
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
