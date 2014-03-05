/**
 * User: ADorsett
 * Date: 3/4/14
 * Time: 9:03 PM
 */

function mapScroll(){
    $(window).scroll(function() {
        var scrollAmount = $(window).scrollTop();
        if (scrollAmount > 200) {
            $("#map_div").css("margin-top", scrollAmount - 263);
        } else {
            $("#map_div").css("margin-top", -63);
        }
    });
}

function mapInit() {
    map = new OpenLayers.Map("OSMap");
    var mapnik         = new OpenLayers.Layer.OSM();
    var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
    var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
    //Maré
    var lon			   = -43.2437142;
    var lat			   = -22.8574805;

    var position       = new OpenLayers.LonLat(lon,lat).transform( fromProjection, toProjection);
    var zoom           = 15;

    var markers = new OpenLayers.Layer.Markers( "Markers" );
    map.addLayer(markers);
    markers.addMarker(new OpenLayers.Marker(position));

    var lon2		   = -43.2427142;
    var lat2		   = -22.8584805;
    var position2       = new OpenLayers.LonLat(lon2,lat2).transform( fromProjection, toProjection);
    markers.addMarker(new OpenLayers.Marker(position2));


    map.addLayer(mapnik);
    map.setCenter(position, zoom );
}