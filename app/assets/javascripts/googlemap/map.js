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
      draggable:true,
      animation: google.maps.Animation.DROP,
      icon: "/assets/markers/orange_marker.png"
    });
    console.log("Added marker to page at " + markerLoc);

    // We only want to add dragging event listeners if the New Report
    // form is visible.
    if ( $("#new_report").is(":visible") )
    {
      // We only want to add handlers to map clicks to allow moving the marker when clicked.
      google.maps.event.addListener(map, 'click', function(clickEvent) {
        console.log('Mouse clicked at ' + clickEvent.latLng.lat());
        window.maps.updateHTMLFormAddressFromPosition(clickEvent.latLng);

        var latitude = clickEvent.latLng.lat();
        var longitude = clickEvent.latLng.lng();
        window.maps.updateHTMLFormLocation(latitude, longitude);

        // NOTE: This creates a recursive call.
        createOrUpdateNewMarker(clickEvent.latLng);
      });

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
        window.maps.updateHTMLFormAddressFromPosition(position);
      });
    }
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

          // This is a bit overkill, but for now it assures us that the new marker
          // persists across tabbing.
          window.maps.hideMarker(newmarker);
          newmarker = null
          window.maps.hideMarkers()
          window.maps.markers = []
	        createOrUpdateNewMarker(markerLoc);
        }
      },
      error:    function() { window.maps.showError();   },
      complete: function() { window.maps.hideLoading(); }
    });
  });


  // NOTE: Ideally, these listeners will be refactored out into assets/map.js
  // so that we can reuse them for both ArcGis and GoogleMaps. That will
  // require checking for (typeof esri) and then making a decision how to
  // deal with the specific API.
  $('#make_report_button').on('click', function(){
    window.maps.hideMarkers()

    // We only want to add handlers to map clicks to allow moving the marker when clicked.
    google.maps.event.addListener(map, 'click', function(clickEvent) {
      map.setZoom(STREET_ZOOM);
      map.panTo(clickEvent.latLng);
      console.log('Mouse clicked at ' + clickEvent.latLng.lat());
      var latitude = clickEvent.latLng.lat();
      var longitude = clickEvent.latLng.lng();
      window.maps.updateHTMLFormLocation(latitude, longitude);
      window.maps.updateHTMLFormAddressFromPosition(clickEvent.latLng);
      createOrUpdateNewMarker(clickEvent.latLng);
    });
  });


  // A more efficient way is to keep the markers in memory, and simply
  // display them. For now, we're using this quick hack that doesn't add much
  // overhead to development efforts.
  $('#all_reports_button').on('click', function(){
    window.maps.hideMarker(newmarker);
    newmarker = null;

    map.setZoom(REGION_ZOOM);
    google.maps.event.clearInstanceListeners(map);
    window.maps.hideMarkers()
    window.maps.markers = []
    window.maps.populateGoogleMaps(openLocations, map, "open");
    window.maps.populateGoogleMaps(eliminatedLocations, map, "eliminated");
  })

  $('#open_reports_button').on('click', function(){
    window.maps.hideMarker(newmarker);
    newmarker = null;

    map.setZoom(REGION_ZOOM);
    google.maps.event.clearInstanceListeners(map);
    window.maps.hideMarkers()
    window.maps.markers = []
    window.maps.populateGoogleMaps(openLocations, map, "open");
  })

  $('#eliminated_reports_button').on('click', function(){
    window.maps.hideMarker(newmarker);
    newmarker = null;

    map.setZoom(REGION_ZOOM);
    google.maps.event.clearInstanceListeners(map);
    window.maps.hideMarkers()
    window.maps.markers = []
    window.maps.populateGoogleMaps(eliminatedLocations, map, "eliminated");
  })



});
