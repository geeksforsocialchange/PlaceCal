
document.MapHandler = {
  mapContainer: null,
  map: null,
  mapIcon: null,
  markers: [],

  initialize(args) {
    if(Object.keys(args).length == 0) return;

    console.log("starting map")
    let map = this._findOrCreateMap(args);
    if(!map) return;

    map.setView(args.center, args.zoom);

    console.log('destroying markers: c=', this.markers.length);
    this.markers.forEach( m => m.remove() );

    console.log('adding markers: c=', args.markers.length);
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
    console.log("parent=", parent);

    if(!this.mapContainer) {

      this.mapContainer = document.createElement('div');
      this.mapContainer.classList.add('map');

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

    this.mapContainer.classList.remove('map--single', 'map--multiple');
    this.mapContainer.classList.add(args.styleClass);

    parent.appendChild(this.mapContainer);

    this.map.invalidateSize(true);
    return this.map;
  }
}

/* this is loaded only once on initial page load */
console.log('setting up map loader');
//document.mapData = {};

document.addEventListener("turbo:load", () => {
  console.log("page nav,  mapData=", document.mapData);
  document.MapHandler.initialize(document.mapData);
});
