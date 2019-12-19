// jQuery.extend(Behaviors, {
//   map: {
//   	set_address_latlng: function (full_address, map){
//       geocoder = new google.maps.Geocoder();
//       geocoder.geocode({ 'address': full_address }, function(results, status) {
//         if (status == google.maps.GeocoderStatus.OK) {
//           var loc = [results[0].geometry.location.lat(), results[0].geometry.location.lng()];
//           //Set Marker on address lat long
//           Behaviors.map.set_marker(map, loc, 'partner-form');
//         }else{
//           console.log("Invalid")
//         }
//       });
//     },
//
//     set_marker: function (map, latlong, type){
//       type = typeof type === 'undefined' ? null : type
//
//       var mapIcon = Behaviors.map.set_icon(type)
//       var markerArray = []
//       marker = L.marker(latlong, {icon: mapIcon}).addTo(map);
//       map.setView(latlong, 15);
//       L.tileLayer('https://api.mapbox.com/styles/v1/studiosquid/cj9o6fykz441q2rqyqzkaal37/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1Ijoic3R1ZGlvc3F1aWQiLCJhIjoiY2o5bzZmNzhvMWI2dTJ3bnQ1aHFnd3loYSJ9.NC3T07dEr_Aw7wo1O8aF-g', {
//                 attribution: 'PlaceCal',
//                 maxZoom: 18,
//       }).addTo(map);
//     },
//
//     set_icon: function (type){
//       var icon_image
//       if(type == 'partner-form') icon_image = $('#map-pin-div').data('url');
//       return L.icon({
//         iconUrl: icon_image,
//         shadowUrl: icon_image,
//         iconSize:     [46, 43], // size of the icon
//         shadowSize:   [46, 43], // size of the shadow
//         iconAnchor:   [17, 0], // point of the icon which will correspond to marker's location
//         shadowAnchor: [17, 0],  // the same for the shadow
//         popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
//       });
//     }
//   }
// });
