
document.MapHandler = {
  mapContainer: null,
  map: null,
  mapIcon: null,
  markers: [],

  initialize(args) {
    if(Object.keys(args).length == 0) return;

    let map = this._findOrCreateMap(args);
    if(!map) return;

    map.setView(args.center, args.zoom);

		// if markers exist delete them and replace with args.markers
    this.markers.forEach( m => m.remove() );

    this.markers = args.markers.map( m => {
      let mapMarker = L.marker(m.position, {icon: this.mapIcon});
      mapMarker.addTo(map);
      mapMarker.bindPopup(m.anchor, { permanent: true, closeButton: false });
      return mapMarker;
    });

    // Create a group for all markers and add to map
    let markerGroup = L.featureGroup(this.markers);
    map.fitBounds(markerGroup.getBounds(), {maxZoom: args.zoom});
  },

  _findOrCreateMap(args) {
    let parent = document.getElementById('js-map-outer');
    if(!parent) return null;

    if(!this.mapContainer) {

      this.mapContainer = document.createElement('div');
      this.mapContainer.classList.add('map');

			// is this where the map is made
      this.map = L.map(this.mapContainer);
      this.map.scrollWheelZoom.disable();

      // Add the basemap
      let layer = L.tileLayer(args.tilesetUrl, {
        attribution: 'PlaceCal',
        maxZoom: 18,
      });
      layer.addTo(this.map);

      if(!this.mapIcon) {
        this.mapIcon = L.icon({
          iconUrl: args.iconUrl,
          shadowUrl: args.shadowUrl,

          iconSize:     [46, 43], // size of the icon
          shadowSize:   [46, 43], // size of the shadow
          iconAnchor:   [17, 0], // point of the icon which will correspond to marker's location
          shadowAnchor: [17, 0],  // the same for the shadow
          popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
        });
      }
    }

		// remove all the style options then add back the ones from args
    this.mapContainer.classList.remove('map--single', 'map--multiple', 'map--compact');
    args.styleClass.forEach( style =>
      this.mapContainer.classList.add(style)
    );

    parent.appendChild(this.mapContainer);

    this.map.invalidateSize(true);
    return this.map;
  }
}

/* this is loaded only once on initial page load */
if(typeof(document.mapData) == 'undefined') {
  document.mapData = {};
}

document.addEventListener("turbo:load", () => {
  document.MapHandler.initialize(document.mapData);
});
