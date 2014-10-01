// TODO @animeshpathak Replace this completely with google Maps calls

var GMAP_API_KEY = "AIzaSyDGcpQfu7LSPkd9AJnQ0cztYylHa-fyE18" ;
var GMAPS_VERSION = 3.17; //latest stable version
var REGION_ZOOM = 14; // the zoom level at which we see the entire neighborhood
var STREET_ZOOM = 18; // the zoom level at which we see street details



/*
var size         = new OpenLayers.Size(64,64);
var offset       = new OpenLayers.Pixel(15,15);
var greyMarker   = new OpenLayers.Icon("/assets/markers/grey_marker.png", size, offset);
var orangeMarker = new OpenLayers.Icon("/assets/markers/orange_marker.png", size, offset);
var map, fromProjection, toProjection, markersLayer; //filled in later in the init method

*/

// Declare different reports and their counts.
// var open_markers       = [{"latitude":680076.589943705,"longitude":7472195.75002062},{"latitude":680266.295950687,"longitude":7471747.54590176},{"latitude":null,"longitude":null},{"latitude":680136.126249498,"longitude":7472180.49977604},{"latitude":680438.592084289,"longitude":7471591.68855667},{"latitude":null,"longitude":null},{"latitude":680108.133417463,"longitude":7471539.19692729},{"latitude":680554.467877344,"longitude":7471694.63723277},{"latitude":680640.030212599,"longitude":7469459.90966016},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":649376.44687463,"longitude":7466007.38511691},{"latitude":680640.030212599,"longitude":7469459.90966016},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":649376.44687463,"longitude":7466007.38511691},{"latitude":680187.463811618,"longitude":7471828.27773749},{"latitude":680524.886695228,"longitude":7472123.62055022},{"latitude":680368.454934851,"longitude":7471325.96790595},{"latitude":680381.328488594,"longitude":7471666.84702602},{"latitude":680166.653151724,"longitude":7472173.01372173},{"latitude":680259.700743438,"longitude":7471660.01585756},{"latitude":680263.643753164,"longitude":7471735.49323853},{"latitude":680420.339797968,"longitude":7471697.85655889},{"latitude":680232.956122846,"longitude":7471618.92631448},{"latitude":680381.749919285,"longitude":7471681.89328903},{"latitude":680270.004762472,"longitude":7471540.24875555},{"latitude":680364.119871703,"longitude":7471677.81955198},{"latitude":680409.288615454,"longitude":7471625.89279749},{"latitude":680273.585106924,"longitude":7471682.34711666},{"latitude":680006.721098777,"longitude":7471965.07382638},{"latitude":680311.194879195,"longitude":7469799.22640378},{"latitude":680174.301979961,"longitude":7472178.11379289},{"latitude":680363.325877906,"longitude":7471375.9223351},{"latitude":680214.114281982,"longitude":7471735.62092319},{"latitude":680138.379637579,"longitude":7471676.62240998},{"latitude":680069.318721186,"longitude":7471870.32196603},{"latitude":680554.998524021,"longitude":7471683.78450986},{"latitude":680389.172694819,"longitude":7471620.55595628},{"latitude":680438.592084289,"longitude":7471591.68855667},{"latitude":680528.207053164,"longitude":7471704.09216844},{"latitude":680013.940517328,"longitude":7471958.76164081},{"latitude":680011.160094995,"longitude":7471625.81004978},{"latitude":680364.650251991,"longitude":7471350.82393932},{"latitude":680351.35707284,"longitude":7471290.54942897},{"latitude":680471.684933169,"longitude":7471706.45460576},{"latitude":680188.621394713,"longitude":7471688.57994012},{"latitude":680005.10430685,"longitude":7471651.62758843},{"latitude":680275.838495006,"longitude":7471219.71078641},{"latitude":680117.303428781,"longitude":7471848.30142692},{"latitude":680231.155721273,"longitude":7471327.26017706},{"latitude":680005.10430685,"longitude":7471651.62758843},{"latitude":680580.67481103,"longitude":7471449.58277414},{"latitude":680166.653151724,"longitude":7472173.01372173}]
// var eliminated_markers = [{"latitude":665362.745024063,"longitude":7474606.48739226},{"latitude":680104.548246328,"longitude":7472050.94648395},{"latitude":680150.14099209,"longitude":7471631.59984186},{"latitude":680218.57489931,"longitude":7471251.92155899}]
// var open_markers       = [{"latitude":679951.633992295,"longitude":7467035.31532869},{"latitude":680322.866630597,"longitude":7471654.98200661},{"latitude":680526.082154943,"longitude":7471241.1542872},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":680008.032596832,"longitude":7471956.60802198},{"latitude":680303.424342065,"longitude":7471600.83667657},{"latitude":680517.659561321,"longitude":7469423.16654554},{"latitude":680345.297342244,"longitude":7471265.87294889},{"latitude":680295.456740526,"longitude":7471833.0079215},{"latitude":680266.295950687,"longitude":7471747.54590176},{"latitude":null,"longitude":null},{"latitude":680136.126249498,"longitude":7472180.49977604},{"latitude":680438.592084289,"longitude":7471591.68855667},{"latitude":null,"longitude":null},{"latitude":680554.467877344,"longitude":7471694.63723277},{"latitude":680640.030212599,"longitude":7469459.90966016},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":680517.659561321,"longitude":7469423.16654554},{"latitude":680640.030212599,"longitude":7469459.90966016},{"latitude":680615.149921423,"longitude":7471308.69006072},{"latitude":680517.659561321,"longitude":7469423.16654554},{"latitude":680187.463811618,"longitude":7471828.27773749},{"latitude":680524.886695228,"longitude":7472123.62055022},{"latitude":680368.454934851,"longitude":7471325.96790595},{"latitude":680381.328488594,"longitude":7471666.84702602},{"latitude":680166.653151724,"longitude":7472173.01372173},{"latitude":680259.700743438,"longitude":7471660.01585756},{"latitude":680263.643753164,"longitude":7471735.49323853},{"latitude":680420.339797968,"longitude":7471697.85655889},{"latitude":680232.956122846,"longitude":7471618.92631448},{"latitude":680381.749919285,"longitude":7471681.89328903},{"latitude":680270.004762472,"longitude":7471540.24875555},{"latitude":680364.119871703,"longitude":7471677.81955198},{"latitude":680409.288615454,"longitude":7471625.89279749},{"latitude":680273.585106924,"longitude":7471682.34711666},{"latitude":680006.721098777,"longitude":7471965.07382638},{"latitude":680311.194879195,"longitude":7469799.22640378},{"latitude":680174.301979961,"longitude":7472178.11379289},{"latitude":680363.325877906,"longitude":7471375.9223351},{"latitude":680214.114281982,"longitude":7471735.62092319},{"latitude":680138.379637579,"longitude":7471676.62240998},{"latitude":680069.318721186,"longitude":7471870.32196603},{"latitude":680554.998524021,"longitude":7471683.78450986},{"latitude":680389.172694819,"longitude":7471620.55595628},{"latitude":680438.592084289,"longitude":7471591.68855667},{"latitude":680528.207053164,"longitude":7471704.09216844},{"latitude":680013.940517328,"longitude":7471958.76164081},{"latitude":680011.160094995,"longitude":7471625.81004978},{"latitude":680364.650251991,"longitude":7471350.82393932},{"latitude":680351.35707284,"longitude":7471290.54942897},{"latitude":680471.684933169,"longitude":7471706.45460576},{"latitude":680188.621394713,"longitude":7471688.57994012},{"latitude":680005.10430685,"longitude":7471651.62758843},{"latitude":680275.838495006,"longitude":7471219.71078641},{"latitude":680117.303428781,"longitude":7471848.30142692},{"latitude":680231.155721273,"longitude":7471327.26017706},{"latitude":680005.10430685,"longitude":7471651.62758843},{"latitude":680580.67481103,"longitude":7471449.58277414},{"latitude":680166.653151724,"longitude":7472173.01372173}]
// var eliminated_markers = [{"latitude":680108.133417463,"longitude":7471539.19692729},{"latitude":680108.133417463,"longitude":7471539.19692729},{"latitude":665362.745024063,"longitude":7474606.48739226},{"latitude":680104.548246328,"longitude":7472050.94648395},{"latitude":680150.14099209,"longitude":7471631.59984186},{"latitude":680218.57489931,"longitude":7471251.92155899}]


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

    // There already is a custom listener on an ESRI map. This is only for
    // OSM maps.
    if(typeof esri !== "undefined")
      return

    console.log("It's not ESRI! Trying Google Maps now...");
    var addressString   = $("#report_location_attributes_address").val() + ", Mexico";

    var geocodingUrl = "https://maps.googleapis.com/maps/api/geocode/json?address="+ escape(addressString) +"&key=" + GMAP_API_KEY;

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
