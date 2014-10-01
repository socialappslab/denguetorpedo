// TODO @animeshpathak Replace this completely with google Maps calls

var GMAP_API_KEY = "AIzaSyDGcpQfu7LSPkd9AJnQ0cztYylHa-fyE18" ;
var GMAPS_VERSION = 3.17; //latest stable version
var REGION_ZOOM = 14; // the zoom level at which we see the entire neighborhood
var STREET_ZOOM = 18; // the zoom level at which we see street details

var coordinates = [];
var map; //this is a shared variable used by all methods.
var newmarker = null; // this is a global var for the new marker, to be updated whenever a new marker is added


// Do not declare shared variables after this line
//-------------------------------------------------------------------------
// Helpers
//--------

// Creates a new marker at markerLoc and stores it in newMarker.
// pans and zooms map as needed
// does NOT update the HTML form elements
function createOrUpdateNewMarker(markerLoc){
  map.panTo(markerLoc);
  map.setZoom(STREET_ZOOM);
  if (newmarker == null) {
    newmarker = new google.maps.Marker({
      position: markerLoc,
      map: map,
      draggable:true,
      animation: google.maps.Animation.DROP,
    });
    console.log("Added marker to page at " + markerLoc);
    // Add dragging event listeners.

    google.maps.event.addListener(newmarker, 'dragstart', function() {
      console.log('Dragging start.');
    });

    google.maps.event.addListener(newmarker, 'drag', function() {
      console.log('Dragging... now at ' + newmarker.getPosition());
    });

    google.maps.event.addListener(newmarker, 'dragend', function() {
      var position = newmarker.getPosition();
      console.log('Drag ended. now at ' + position);
      window.maps.updateHTMLFormLocation(position.lat(), position.lng());
    });
  } else {
    newmarker.setPosition(markerLoc)
    console.log("Updated marker location to " + markerLoc);
  }
}

$(document).ready(function() {
  console.log("Ready to display map using Google Maps!!")
  var script = document.createElement('script');
  script.type = 'text/javascript';
  //sensor parameter no longer needed
  script.src = 'https://maps.googleapis.com/maps/api/js?v='+GMAPS_VERSION+'&callback=window.maps.initializeGoogleMaps';
  document.body.appendChild(script);

  // Listener for location attribute updates
  $("#new_report #report_location_attributes_address").on("change", function()
  {
    console.log("Starting geocoding!")
    window.maps.showLoading();
    console.log("It's not ESRI! Trying Google Maps now...");
    var addressString = $("#report_location_attributes_address").val() + ", Mexico";
    var geocodingUrl  = "https://maps.googleapis.com/maps/api/geocode/json?address="+ escape(addressString) +"&key=" + GMAP_API_KEY;
    console.log(geocodingUrl);

    $.ajax({
      url: geocodingUrl,
      type: "GET",
      timeout: 5000,
      success: function(response) {
        //response is a PlainObject, i.e., key-value pairs
        var results = response.results;
        if (results === undefined || results.length == 0)
          window.maps.showError()
        else
        {
          console.log("Starting to plot...");
          var latitude  = results[0].geometry.location.lat;
          var longitude = results[0].geometry.location.lng;
	        window.maps.updateHTMLFormLocation(latitude, longitude);
          window.maps.hideError()

          console.log("("+latitude+","+longitude+")");
          var markerLoc = new google.maps.LatLng(latitude, longitude);
	        createOrUpdateNewMarker(markerLoc);
        }
      },
      error: function()    { window.maps.showError() },
      complete: function() { window.maps.hideLoading(); }
    });
  });
});
