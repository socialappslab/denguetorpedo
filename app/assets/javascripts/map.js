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
  var heatmapData = Array(locations.length);
  for(var i = 0; i < locations.length; i++) {
    var latitude  = locations[i].latitude;
    var longitude = locations[i].longitude;
    heatmapData[i] = new google.maps.LatLng(latitude, longitude);
  }

  var heatmap = new google.maps.visualization.HeatmapLayer({
    data: heatmapData,
    radius: 150,
    gradient: [
    "rgba(0, 255, 255, 0)",
    "rgba(235,255,87,1)",
    "rgba(235,240,85, 1)",
    "rgba(234,225,82, 1)",
    "rgba(234,210,80,1)",
    "rgba(234,195,78,1)",
    "rgba(233,180,76,1)",
    "rgba(233,165,74,1)",
    "rgba(233,151,71,1)",
    "rgba(232,136,69,1)",
    "rgba(232,121,67,1)",
    "rgba(232,106,65,1)",
    "rgba(231,91,62,1)",
    "rgba(231,76,60,1)"
    ]
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
  map = new google.maps.Map(document.getElementById('gmap'), mapOptions);
  window.maps.hideLoading();

  // See if lat and long are set, if so, this is an error page, and we should set
  //the marker
  var oldlat  = $("#new_report #report_location_attributes_latitude").val();
  var oldlong = $("#new_report #report_location_attributes_longitude").val();
  if (oldlat != "" && oldlong != "")
  {
    var markerLoc = new google.maps.LatLng(oldlat, oldlong);
    createOrUpdateNewMarker(markerLoc);
  }

  // Set up heatmap.
  if ( !$("#new_report").is(":visible") )
    window.maps.setupHeatMap(openLocations, map);

  // Initialize the geocoder.
  geocoder = new google.maps.Geocoder();
}
