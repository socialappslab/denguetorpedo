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
  else {
    newmarker.setPosition(markerLoc)
    console.log("Updated marker location to " + markerLoc);
  }
}

$(document).ready(function() {
  console.log("Ready to display map using Google Maps!!")
  var script = document.createElement('script');
  script.type = 'text/javascript';
  //sensor parameter no longer needed
  script.src = 'https://maps.googleapis.com/maps/api/js?v='+GMAPS_VERSION+'&callback=initializeGMaps';
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
        if (results === undefined || results.length == 0) {
          window.maps.showError()
          window.maps.updateHTMLFormLocation("", "")
          window.maps.hideMarker(newmarker);
          newmarker = null
        }
        else
        {
          window.maps.hideError()
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
      error:    function() {
        window.maps.showError();
        window.maps.updateHTMLFormLocation("", "")
        window.maps.hideMarker(newmarker);
        newmarker = null
      },
      complete: function() { window.maps.hideLoading(); }
    });
  });


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
  }



  //zoom and center map on the location of this marker
  $('a.mapa').on('click', function(event){
    var reportLoc = $(this).data('location');
    var reportLatLng = new google.maps.LatLng(reportLoc.latitude, reportLoc.longitude);
    console.log('I will now zoom and pan the map to this marker at ' + reportLatLng);
    map.panTo(reportLatLng);
    map.setZoom(STREET_ZOOM);
    event.preventDefault();
    event.stopPropagation();
  });



});
