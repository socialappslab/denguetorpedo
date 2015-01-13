window.maps = {};
window.maps.markers = [];

window.maps.populateGoogleMaps = function(locations, map, locationType) {
  // Populate the map with existing open locations.
  var latitude, longitude, icon;
  if (locationType == "open")
    var icon = "/assets/markers/orange_marker.png"
  else
    var icon = "/assets/markers/grey_marker.png"

  for(var i = 0; i < locations.length; i++) {
    var latitude  = locations[i].latitude;
    var longitude = locations[i].longitude;
    var markerLoc = new google.maps.LatLng(latitude, longitude);
    marker = new google.maps.Marker({
      position: markerLoc,
      map: map,
      draggable:false,
      animation: google.maps.Animation.DROP,
      icon: icon
    });
    window.maps.markers.push(marker);
  }
}

//set up a heatmap
window.maps.setupHeatMap = function(locations, map){
  console.log("setting up heatmap now");
  var heatmapData = Array(locations.length);
  for(var i = 0; i < locations.length; i++) {
    var latitude  = locations[i].latitude;
    var longitude = locations[i].longitude;
    heatmapData[i] = new google.maps.LatLng(latitude, longitude);
  }

  var heatmap = new google.maps.visualization.HeatmapLayer({
    data: heatmapData,
    radius: 100
  });
  heatmap.setMap(map);

}

window.maps.showLoading = function(){
  $("#loading").show();
}

window.maps.hideLoading = function(){
  $("#loading").hide();
}

window.maps.showError = function(){
  $("#map-error-description").show();
}

window.maps.hideError = function(){
  $("#map-error-description").hide();
}

window.maps.showMarkers = function(map){
  for (var i = 0; i < window.maps.markers.length; i++) {
    window.maps.markers[i].setMap(map);
  }
}

window.maps.hideMarkers = function(){
  if(typeof esri !== "undefined") {
    map.graphics.clear();
  }
  else {
    for (var i = 0; i < window.maps.markers.length; i++) {
      window.maps.markers[i].setMap(null);
    }
  }
}

window.maps.hideMarker = function(marker){
  // Remove the newmarker from view.
  if (marker)
    marker.setMap(null);
}

// NOTE: DO NOT use lat, long as parameters to the function.
// This causes an error in the YUI compressor:
// [ERROR] in /tmp/yui_compress20140930-1167-32nwix 39:48:missing formal parameter
window.maps.updateHTMLFormLocation = function(latitude, longitude){
  $("#new_report #report_location_attributes_latitude").val(latitude);
  $("#new_report #report_location_attributes_longitude").val(longitude);
}

// calls the Google (reverse) geocoding API and updates the address field
window.maps.updateHTMLFormAddressFromPosition = function(pos) {
  if(! no_address_lookup){
    console.log("Reverse-Geocoding now...");
    geocoder.geocode({ latLng: pos }, function(responses) {
      if (responses && responses.length > 0)
        $("#new_report #report_location_attributes_address").val(responses[0].formatted_address);
    });
  }
}


window.maps.initializeGoogleMaps = function(){
  var mapOptions = {
    zoom: REGION_ZOOM,
    zoomControl: false,
    streetViewControl: false,
    scrollwheel: false,
    disableDoubleClickZoom: true,
    center: new google.maps.LatLng(communityLatitude, communityLongitude)
    };
  // Initialize the map, and add the geographical layer to it.
  map = new google.maps.Map(document.getElementById('gmap'),
      mapOptions);
  window.maps.hideLoading();

  //see if lat and long are set, if so, this is an error page, and we should set
  //the marker
  var oldlat = $("#new_report #report_location_attributes_latitude").val();
  var oldlong = $("#new_report #report_location_attributes_longitude").val();
  if (oldlat != "" && oldlong != ""){
    //we want none of them to be blank
    var markerLoc = new google.maps.LatLng(oldlat, oldlong);
    console.log("setting up stored marker at "+ markerLoc);
    createOrUpdateNewMarker(markerLoc);
  }

  // TODO: Right now, this is build with the assumption that the map renders in
  // only /neighborhoods/:id/reports OR /neighborhoods/:id/csv_reports. Let's
  // update this accordingly.
  if ( !$("#new_report").is(":visible") && $("#report_buttons").length > 0 )
  {
//    window.maps.populateGoogleMaps(openLocations, map, "open");
//    window.maps.populateGoogleMaps(eliminatedLocations, map, "eliminated");
    window.maps.setupHeatMap(openLocations, map);

  }

   //initialize the geocoder
   geocoder = new google.maps.Geocoder();
}
