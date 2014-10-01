//TODO change this Tepalciongo-specific info to be more generic
var COMMUNITY_LON = -98.8460549;
var COMMUNITY_LAT = 18.5957189;

window.maps = {};

window.maps.populateGoogleMaps = function(locations, map, locationType) {
  // Populate the map with existing open locations.
  var lat, long;
  if (locationType == "open")
    icon = "/assets/markers/orange_marker.png"
  else
    icon = "/assets/markers/grey_marker.png"

  for(var i = 0; i < locations.length; i++) {
    lat  = locations[i].latitude;
    long = locations[i].longitude;
    var markerLoc = new google.maps.LatLng(lat, long);
    newmarker = new google.maps.Marker({
      position: markerLoc,
      map: map,
      draggable:false,
      animation: google.maps.Animation.DROP,
      icon: icon
    });
  }
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

// NOTE: DO NOT use lat, long as parameters to the function.
// This causes an error in the YUI compressor:
// [ERROR] in /tmp/yui_compress20140930-1167-32nwix 39:48:missing formal parameter
window.maps.updateHTMLFormLocation = function(latitude, longitude){
  $("#new_report #report_location_attributes_latitude").val(latitude);
  $("#new_report #report_location_attributes_longitude").val(longitude);
}

window.maps.initializeGoogleMaps = function(){
  var mapOptions = {
    zoom: REGION_ZOOM,
    center: new google.maps.LatLng(COMMUNITY_LAT, COMMUNITY_LON)
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

  //add handler to map click() event, so as to add or move markers when it is clicked
  google.maps.event.addListener(map, 'click', function(clickEvent) {
    console.log('Mouse clicked at ' + clickEvent.latLng.lat());
    var latitude = clickEvent.latLng.lat();
    var longitude = clickEvent.latLng.lng();
    window.maps.updateHTMLFormLocation(latitude, longitude);
    createOrUpdateNewMarker(clickEvent.latLng);
  });

  window.maps.populateGoogleMaps(openLocations, map, "open");
  window.maps.populateGoogleMaps(eliminatedLocations, map, "eliminated");
}
