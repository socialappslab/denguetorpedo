/**
 * User: ADorsett
 * Date: 3/4/14
 * Time: 9:03 PM
 */


angular.module('dengue_torpedo.controllers',['ngResource', 'timer']).
    controller("MapController", function($scope, Map){
        Map.init();
        Map.scrollLock("map_div");

        //start - for testing
        Map.loadMarkers([[-43.2425729,-22.8592368]]);

        $scope.hide = function(){
            Map.start_new_report();
        }

        $scope.show = function(){
            Map.stop_new_report();
        }
        //end - for testing

    })

angular.module('dengue_torpedo.factories',[]).
    factory('Map',function(){
        var mapFactory = {'saved_markers':[]};
        mapFactory.init = function(){
            var size = new OpenLayers.Size(21,25);
            var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
            var icon = new OpenLayers.Icon('http://www.openlayers.org/dev/img/marker.png', size, offset);

            mapFactory.map = new OpenLayers.Map("OSMap");
            var mapnik = new OpenLayers.Layer.OSM();
            mapFactory.fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
            mapFactory.toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection

            //Maré - Need to change to dynamic
            var lon			   = -43.2437142;
            var lat			   = -22.8574805;

            var position       = new OpenLayers.LonLat(lon,lat).transform( mapFactory.fromProjection, mapFactory.toProjection);


            mapFactory.start_position = position; //temp for testing
            var zoom           = 15;

            mapFactory.current_markers = new OpenLayers.Layer.Markers( "Markers" );
            mapFactory.map.addLayer(mapFactory.current_markers);
            mapFactory.current_markers.addMarker(new OpenLayers.Marker(position,icon));

            var lon2		   = -43.2427142;
            var lat2		   = -22.8584805;
            var position2       = new OpenLayers.LonLat(lon2,lat2).transform(mapFactory.fromProjection, mapFactory.toProjection);
            mapFactory.current_markers.addMarker(new OpenLayers.Marker(position2,icon.clone()));

            mapFactory.map.addLayer(mapnik);
            mapFactory.map.setCenter(position, zoom);

        }
        mapFactory.scrollLock = function(div_id){
            $(window).scroll(function() {
                var scrollAmount = $(window).scrollTop();
                if (scrollAmount > 200) {
                    $("#"+div_id).css("margin-top", scrollAmount - 263);
                } else {
                    $("#"+div_id).css("margin-top", -63);
                }
            });
        }
        mapFactory.loadMarkers = function(positions){
            angular.forEach(positions, function(position){
                // {lon: val, lat: val} format?
                var pos = new OpenLayers.LonLat(position).transform(mapFactory.fromProjection, mapFactory.toProjection);
                mapFactory.current_markers.addMarker(new OpenLayers.Marker(pos));
            });

        }
        mapFactory.start_new_report = function(){
            var position = new OpenLayers.LonLat(-43.2425729,-22.8592368).transform( mapFactory.fromProjection, mapFactory.toProjection);
            mapFactory.map.setCenter(position,17);
            mapFactory.current_markers.setVisibility(false);



        }

        mapFactory.stop_new_report = function(){
            mapFactory.map.setCenter(mapFactory.start_position,15);

            mapFactory.current_markers.setVisibility(true);
        }
        return mapFactory;
    })


