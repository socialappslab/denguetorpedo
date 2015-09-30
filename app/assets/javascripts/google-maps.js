window.maps = {};
window.maps.markers = [];

window.maps.hideLoading = function(){
  $("#loading").hide();
}

// NOTE: DO NOT use lat, long as parameters to the function.
// This causes an error in the YUI compressor:
// [ERROR] in /tmp/yui_compress20140930-1167-32nwix 39:48:missing formal parameter
window.maps.updateHTMLFormLocation = function(latitude, longitude){
  $("#new_report #report_location_attributes_latitude").val(latitude);
  $("#new_report #report_location_attributes_longitude").val(longitude);
}


// TODO @animeshpathak Replace this completely with google Maps calls
var GMAP_API_KEY = "AIzaSyDGcpQfu7LSPkd9AJnQ0cztYylHa-fyE18" ;
var GMAPS_VERSION = 3.17; //latest stable version
var REGION_ZOOM = 14; // the zoom level at which we see the entire neighborhood
var STREET_ZOOM = 16; // the zoom level at which we see street details

var map; //this is a shared variable used by all methods.
var newmarker = null; // this is a global var for the new marker, to be updated whenever a new marker is added
var geocoder = null; // the GeoCoder object we will use to make geocoding/reverse-geocoding requests

// Do not declare shared variables after this line
//-------------------------------------------------------------------------
// Helpers
//--------

// Creates a new marker at markerLoc and stores it in newMarker.
// pans and zooms map as needed
// does NOT update the HTML form elements
function createOrUpdateNewMarker(markerLoc){
  if (newmarker == null) {
    newmarker = new google.maps.Marker({
      position: markerLoc,
      map: map,
      draggable: true,
      animation: google.maps.Animation.DROP,
      icon: "/assets/markers/orange_marker.png"
    });
    console.log("Added marker to page at " + markerLoc);


    // We only want to add handlers to map clicks to allow moving the marker when clicked.
    google.maps.event.addListener(map, 'click', function(clickEvent) {
      var latitude = clickEvent.latLng.lat();
      var longitude = clickEvent.latLng.lng();
      window.maps.updateHTMLFormLocation(latitude, longitude);

      // NOTE: This creates a recursive call.
      createOrUpdateNewMarker(clickEvent.latLng);
    });
    google.maps.event.addListener(newmarker, 'dragend', function() {
      var position = newmarker.getPosition();
      window.maps.updateHTMLFormLocation(position.lat(), position.lng());
    });
  } else {
    newmarker.setPosition(markerLoc)
    console.log("Updated marker location to " + markerLoc);
  }
}

$(document).ready(function() {
  var script = document.createElement('script');
  script.type = 'text/javascript';
  //sensor parameter no longer needed
  script.src = 'https://maps.googleapis.com/maps/api/js?v='+GMAPS_VERSION+'&callback=initializeGMaps';
  document.body.appendChild(script);

  initializeGMaps = function()
  {
    var mapOptions = {
      zoom: REGION_ZOOM,
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

   //initialize the geocoder
   geocoder = new google.maps.Geocoder();

    // We only want to add handlers to map clicks to allow moving the marker when clicked.
    google.maps.event.addListener(map, 'click', function(clickEvent) {
      map.setZoom(STREET_ZOOM);
      map.panTo(clickEvent.latLng);
      console.log('Mouse clicked at ' + clickEvent.latLng.lat());
      var latitude = clickEvent.latLng.lat();
      var longitude = clickEvent.latLng.lng();
      window.maps.updateHTMLFormLocation(latitude, longitude);
      createOrUpdateNewMarker(clickEvent.latLng);
    });
  }



  //zoom and center map on the location of this marker
  $('a.mapa').on('click', function(event){
    var reportLoc = $(this).data('location');
    var reportLatLng = new google.maps.LatLng(reportLoc.latitude, reportLoc.longitude);
    map.panTo(reportLatLng);
    map.setZoom(STREET_ZOOM);
    event.preventDefault();
    event.stopPropagation();
  });

});