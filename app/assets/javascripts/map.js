/**
 * User: ADorsett
 * Date: 3/4/14
 * Time: 9:03 PM
 */


//angular.module('dengue_torpedo.controllers',['ngResource', 'timer']).
//    controller("MapController", function($scope){
//
//
//
//
//    })

//angular.module('dengue_torpedo.factories',[]).
//    factory('Map',function(){
//        //primarily for reference
//        var mapFactory = {
//            'callbacks':{},
//            'loading':{
//                'div':'',
//                'start':null,
//                'stop':null
//            },
//            'operations':{
//                'addGraphic':null,
//                'getLocation':null,
//                'loadMapMarkers':null,
//                'scrollLock':null
//            },
//            'map_variables':{
//                'input_x':'',
//                'input_y':''
//            },
//            'map':null
//        };
//
//        //takes in div name of map and loading overlay
//        mapFactory.init = function(map_instance,loading_div){
//            require(required_components,
//                function(Map, Draw, Locator, Tiled,
//                        SpatialReference, Point, Geometry,
//                        Graphic, SimpleMarkerSymbol,
//                        SimpleLineSymbol, TextSymbol, Color,
//                        PictureMarkerSymbol, ClassBreaksRenderer, Popup,PopupTemplate, domConstruct, dom, InfoTemplate)
//                {
//
//                    mapFactory.loading.div = loading_div;
//                    console.log('start of init');
//
//                    //Load map variables, see function at end of factory
//                    loadMapVariables();
//                    mapFactory.map = new Map(map_instance, {
//                        center: mapFactory.map_variables.center,
//                        zoom: mapFactory.map_variables.zoom_level,
//                        extent: mapFactory.map_variables.custom_extent
////                        infoWindow: mapFactory.map_variables.popup
//
//                    });
//
//                    console.log('created map');
//                    console.log(mapFactory.map);
//
//
//                    mapFactory.map_variables.tiled = new Tiled("http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Basico/mapa_basico_utm/MapServer");
//
//
//
//                    mapFactory.map.addLayer(mapFactory.map_variables.tiled);
//
//                    mapFactory.map.on("update-start", mapFactory.loading.start);
//                    mapFactory.map.on("update-end", mapFactory.loading.stop);
//                    temp.on("draw-end", addGraphic);
//                    temp.activate("point");
//                    mapFactory.map.on("load", function() {
//                        var temp = new Draw(mapFactory.map);
//                        temp.on("draw-end", addGraphic);
//                        temp.activate("point");
////                        mapFactory.map.infoWindow.resize(300, 200)
//
//                    });
//
//                    //used to assign map variables during init()
//                    function loadMapVariables(){
//
//                        // TODO: Not sure what this is used for, look into
//                        mapFactory.map_variables.custom_extent = new esri.geometry.Extent(667070.412263838,
//                            7456962.88258577,
//                            688175.480935968,
//                            7475960.60361382,
//                            new esri.SpatialReference({"wkid":29193}));
//
//
////                        mapFactory.map_variables.popup = new Popup({
////                            highlight: false
////                        }, domConstruct.create("div"));
//
//                        // TODO: Can this be cached?
//                        mapFactory.map_variables.tiled = new Tiled("http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Basico/mapa_basico_utm/MapServer");
//
//                        mapFactory.map_variables.zoom_level = 4;
//                        mapFactory.map_variables.marker_colors = {};
//
//                        // TODO: Does it make more sense to make markers local?
//                        var picBaseUrl = "http://static.arcgis.com/images/Symbols/Shapes/";
//                        mapFactory.map_variables.marker_colors.gray = new PictureMarkerSymbol(picBaseUrl + "BlackPin1LargeB.png", 40, 40).setOffset(0, 15);
//                        mapFactory.map_variables.marker_colors.blue = new PictureMarkerSymbol(picBaseUrl + "BluePin1LargeB.png", 40, 40).setOffset(0, 15);
//                        mapFactory.map_variables.marker_colors.red = new PictureMarkerSymbol(picBaseUrl + "OrangePin1LargeB.png", 40, 40).setOffset(0, 15);
//                        mapFactory.map_variables.marker_colors.grey = new PictureMarkerSymbol("/assets/markers/grey_marker.png", 48, 48).setOffset(0, 0);
//                        mapFactory.map_variables.marker_colors.mixed = new PictureMarkerSymbol("/assets/markers/mixed_marker.png", 48, 48).setOffset(0, 0);
//                        mapFactory.map_variables.marker_colors.orange = new PictureMarkerSymbol("/assets/markers/orange_marker.png", 48, 48).setOffset(0, 0);
//
//                        // TODO: Is this a static location for Mare? If so we need to make dynamic
//                        mapFactory.map_variables.center = new Point(680291.2151545063,
//                            7470751.29586681,
//                            new esri.SpatialReference({wkid: 29193}));
//
//                    }
//
//                });
//        }
//        //used for ajax calls
//        mapFactory.callbacks = {
//            'new_report':{
//                'success': function(m){
//                    mapFactory.map.graphics.clear();
//                    var candidates = m.candidates;
//
//                    // ? if point exists
//                    // ? Does candidates return multiple possibilities?
//                    if (candidates.length > 0) {
//                        mapFactory.map.graphics.add(new Graphic(new Point(candidates[0].location.x, candidates[0].location.y), orange));
//                        mapFactory.map_variables.input_x = candidates[0].location.x;
//                        mapFactory.map_variables.input_y = candidates[0].location.y;
//
//                        mapFactory.map.centerAndZoom(new Point(candidates[0].location.x, candidates[0].location.y, new esri.SpatialReference({"wkid": 29193})), 5);
//                    }
//                },
//                'error': function(m){
//                    //We probably want to change this
//                    console.log(JSON.stringify(m));
//                },
//                'complete': function(){
//                    mapFactory.loading.stop();
//                }
//            }
//        }
//        mapFactory.loading = {
//            'div':'', //this will get assigned in the init function
//            'start':function(loading_div){
//                $(mapFactory.loading.div).show();
//                mapFactory.map.disableMapNavigation();
//                mapFactory.map.hideZoomSlider();
//            },
//            'stop':function(loading_div){
//                $(mapFactory.loading.div).hide();
//                mapFactory.map.enableMapNavigation();
//                mapFactory.map.showZoomSlider();
//        }
//        }
//        mapFactory.operations = {
//            'addGraphic' : function(evt) {
//                mapFactory.map.graphics.clear();
//                mapFactory.map.enableMapNavigation();
//
//                // figure out which symbol to use
//                var symbol = new SimpleMarkerSymbol();
//                symbol.setStyle("STYLE_PATH");
//                symbol.setPath("M 10 10 L30 10 L20 30z");
//                symbol.setColor(new Color("red"));
//
//                $("input#x").val(evt.geometry.x);
//                $("input#y").val(evt.geometry.y);
//                mapFactory.map.graphics.add(new Graphic(evt.geometry, orange));
//                mapFactory.map.centerAt(evt.mapPoint);
//            },
//            'getLocationInfo': function(street_type, street_name, street_number, callbacks){
//                var street_data = street_type + " " + street_name + " " + street_number;
//                $.ajax({
//                    url: "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates",
//                    type: "GET",
//                    dataType: "jsonp",
//                    data: {"f": "pjson", "Street": street_data},
//                    success: callbacks.success(m),
//                    error: callbacks.error(m),
//                    complete: callbacks.complete()
//                });
//            },
//            /*markers = [
//                        {status: open || eliminated,
//                        id:,
//                        x:,
//                        y:,
//                        street_name:,
//                        street_number:,
//                        neighborhood:,
//                        city:,
//                        country:,
//                        }
//
//             */
//            'loadMapMarkers': function(markers){
//                angular.forEach(markers,function(marker){
//                    var graphic;
//                    var template = new InfoTemplate();
//                    template.setTitle(marker.address);
//
//                    // TODO: Needed?
//                    template.content = "<p>Em aberto: </p><br><p>Eliminados: </p>";
//
//                    if(marker.status == 'eliminated'){
//                        graphic = new Graphic(new Point(merker.x, merker.y), mapFactory.map_variables.marker_colors.grey);
//                        template.content = "<p>Eliminados: " + eliminated_count + "</p>";
//                    }
//                    else{
//                        graphic = new Graphic(new Point(marker.x, marker.y), mapFactory.map_variables.marker_colors.orange);
//                        template.content = "<p>Em aberto: " + marker.id + "</p>";
//                    }
//
//                    var textSymbol = new TextSymbol(marker.id).setColor("#000000").setOffset(-11, 8);
//
//                    textGraphic = new Graphic(new Point(marker.x, marker.y), textSymbol);
//                    graphic.setInfoTemplate(template);
//                    textGraphic.setInfoTemplate(template);
//
//                    mapFactory.map.graphics.add(graphic);
//                    mapFactory.map.graphics.add(textGraphic);
//                });
//            },
//            'scrollLock' : function(div_id){
//                $(window).scroll(function() {
//                    var scrollAmount = $(window).scrollTop();
//                    if (scrollAmount > 200) {
//                        $("#"+div_id).css("margin-top", scrollAmount - 263);
//                    } else {
//                        $("#"+div_id).css("margin-top", -63);
//                    }
//                });
//            }
//
//
//        }
//
//
//
//        //required components for esri classes
//        var required_components = [
//            "esri/map",
//            "esri/config",
//            "esri/graphic",
//            "esri/InfoTemplate",
//            "esri/toolbars/draw",
//            "esri/tasks/locator",
//            "esri/layers/ArcGISTiledMapServiceLayer",
//            "esri/SpatialReference",
//            "esri/layers/FeatureLayer",
//            "esri/geometry/Point",
//            "esri/dijit/Popup",
//            "esri/dijit/PopupTemplate",
//            "esri/symbols/SimpleMarkerSymbol",
//            "esri/symbols/SimpleLineSymbol",
//            "esri/symbols/TextSymbol",
//            "esri/symbols/PictureMarkerSymbol",
//            "esri/renderers/ClassBreaksRenderer",
//            "dojo/dom",
//            "dojo/dom-construct",
//            "dojo/_base/Color",
//            "dojo/domReady!"];
//
//        return mapFactory;
//    })
//
//
////if params[:view] == 'make_report'
////:javascript
////
////    $("input#go_to_mare").click(function() {
////        map.centerAndZoom(new Point(680291.2151545063, 7471401.29586681, new esri.SpatialReference({"wkid": 29193})), 5)
////    });
////
////
////});
////- else
////:javascript
////var map;
////var report_div;
////
////require(["esri/map", "esri/toolbars/draw", "esri/tasks/locator", "esri/layers/ArcGISTiledMapServiceLayer", "esri/layers/FeatureLayer", "esri/SpatialReference", "esri/geometry/Point", "esri/config", "esri/graphic", "esri/symbols/SimpleMarkerSymbol", "esri/symbols/SimpleLineSymbol", "esri/symbols/TextSymbol", "dojo/_base/Color", "esri/symbols/PictureMarkerSymbol", "esri/renderers/ClassBreaksRenderer", "esri/dijit/Popup", "esri/dijit/PopupTemplate", "dojo/dom-construct", "dojo/dom", "esri/InfoTemplate", "dojo/domReady!"], function(Map, Draw, Locator, Tiled, FeatureLayer, SpatialReference, Point, Geometry, Graphic, SimpleMarkerSymbol, SimpleLineSymbol, TextSymbol, Color, PictureMarkerSymbol, ClassBreaksRenderer, Popup, PopupTemplate, domConstruct, dom, InfoTemplate) {
////    var customExtent = new esri.geometry.Extent(667070.412263838,7456962.88258577,688175.480935968,7475960.60361382, new esri.SpatialReference({"wkid":29193}));
////
////
////
////   //used for anything?
////    $(".mapa").click(function() {
////        var latitude = $(this).data("latitude");
////        var longitude = $(this).data("longitude");
////
////        map.centerAndZoom(new Point(latitude, longitude, new esri.SpatialReference({"wkid": 29193})), 8);
////
////        report_div = $(this).parent().parent().parent();
////
////        return false;
////    });
////
////    map.on("load", function() {
////
////
////
////    });
////
////    $("input#go_to_mare").click(function() {
////        map.centerAndZoom(new Point(point.x, point.y, new esri.SpatialReference({"wkid": 29193})), 4);
////    });
////
////    map.on("extent-change", function(event) {
////        if (markers.length > 0) {
////            for(var i = 0; i < markers.length; i++) {
////
////                if (event.extent.contains(new Point(markers[i].x, markers[i].y)) || (markers[i].x == null && markers[i].y == null) || (markers[i].x == 0.0 && markers[i].y == 0.0)) {
////                    $($(".rp_report")[i]).show();
////                } else {
////                    $($(".rp_report")[i]).hide();
////                }
////            }
////        } else {
////            for (var i = 0; i < open_markers.length; i++) {
////                if (event.extent.contains(new Point(open_markers[i].x, open_markers[i].y))) {
////                    $($(".rp_report")[i]).show();
////                } else {
////                    $($(".rp_report")[i]).hide();
////                }
////
////            }
////
////            for (var i = 0;i < eliminated_markers.length; i++) {
////                if (event.extent.contains(new Point(eliminated_markers[i].x, eliminated_markers[i].y))) {
////                    $($(".rp_report")[i]).show();
////                } else {
////                    $($(".rp_report")[i]).hide();
////                }
////            }
////        }
////        if (report_div) {
////            $("html, body").scrollTop($(report_div).offset().top - 20);
////        }
////
////
////    });
////
////    var blueGraphic;
////
////    function addGraphic(evt) {
////        if (blueGraphic) {
////            map.graphics.remove(blueGraphic);
////        }
////        map.enableMapNavigation();
////
////        // figure out which symbol to use
////        var symbol = new SimpleMarkerSymbol();
////        symbol.setStyle("STYLE_PATH");
////        symbol.setPath("M 10 10 L30 10 L20 30z");
////        symbol.setColor(new Color("blue"));
////
////        $("input#x").val(evt.geometry.x);
////        $("input#y").val(evt.geometry.y);
////
////        blueGraphic = new Graphic(evt.geometry, symbol);
////        map.graphics.add(blueGraphic);
////        map.centerAt(evt.mapPoint);
////
////    }
////
////    $("#address_search_form").submit(function(e) {
////        e.preventDefault();
////        $.ajax({
////            url: "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates",
////            type: "GET",
////            dataType: "jsonp",
////            data: {"f": "pjson", "Street": $("#address_search").val()},
////            success: function(m) {
////
////                var candidates = m.candidates;
////
////
////                if (candidates.length > 0) {
////                    if (blueGraphic) {
////                        map.graphics.remove(blueGraphic);
////                    }
////                    var symbol = new SimpleMarkerSymbol();
////                    symbol.setStyle("STYLE_PATH");
////                    symbol.setPath("M 10 10 L30 10 L20 30z");
////                    symbol.setColor(new Color("blue"));
////                    blueGraphic = new Graphic(new Point(candidates[0].location.x, candidates[0].location.y), symbol);
////                    map.graphics.add(blueGraphic);
////                    $("input#x").val(candidates[0].location.x);
////                    $("input#y").val(candidates[0].location.y);
////
////                    map.centerAndZoom(new Point(candidates[0].location.x, candidates[0].location.y, new esri.SpatialReference({"wkid": 29193})), 4);
////                }
////            },
////            error: function(m) {
////                console.log(JSON.stringify(m));
////            }
////        });
////
////    });
////
////});
//
//
///* Open Street Map - Save for later implementation if needed
//angular.module('dengue_torpedo.factories',[]).
//    factory('Map',function(){
//        var mapFactory = {'saved_markers':[]};
//        mapFactory.init = function(){
//            var size = new OpenLayers.Size(21,25);
//            var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
//            var icon = new OpenLayers.Icon('http://www.openlayers.org/dev/img/marker.png', size, offset);
//
//            mapFactory.map = new OpenLayers.Map("OSMap");
//            var mapnik = new OpenLayers.Layer.OSM();
//            mapFactory.fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
//            mapFactory.toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
//
//            //Maré - Need to change to dynamic
//            var lon			   = -43.2437142;
//            var lat			   = -22.8574805;
//
//            var position       = new OpenLayers.LonLat(lon,lat).transform( mapFactory.fromProjection, mapFactory.toProjection);
//
//
//            mapFactory.start_position = position; //temp for testing
//            var zoom           = 15;
//
//            mapFactory.current_markers = new OpenLayers.Layer.Markers( "Markers" );
//            mapFactory.map.addLayer(mapFactory.current_markers);
//            mapFactory.current_markers.addMarker(new OpenLayers.Marker(position,icon));
//
//            var lon2		   = -43.2427142;
//            var lat2		   = -22.8584805;
//            var position2       = new OpenLayers.LonLat(lon2,lat2).transform(mapFactory.fromProjection, mapFactory.toProjection);
//            mapFactory.current_markers.addMarker(new OpenLayers.Marker(position2,icon.clone()));
//
//            mapFactory.map.addLayer(mapnik);
//            mapFactory.map.setCenter(position, zoom);
//
//        }
//        mapFactory.scrollLock = function(div_id){
//            $(window).scroll(function() {
//                var scrollAmount = $(window).scrollTop();
//                if (scrollAmount > 200) {
//                    $("#"+div_id).css("margin-top", scrollAmount - 263);
//                } else {
//                    $("#"+div_id).css("margin-top", -63);
//                }
//            });
//        }
//        mapFactory.loadMarkers = function(positions){
//            angular.forEach(positions, function(position){
//                // {lon: val, lat: val} format?
//                var pos = new OpenLayers.LonLat(position).transform(mapFactory.fromProjection, mapFactory.toProjection);
//                mapFactory.current_markers.addMarker(new OpenLayers.Marker(pos));
//            });
//
//        }
//        mapFactory.start_new_report = function(){
//            var position = new OpenLayers.LonLat(-43.2425729,-22.8592368).transform( mapFactory.fromProjection, mapFactory.toProjection);
//            mapFactory.map.setCenter(position,17);
//            mapFactory.current_markers.setVisibility(false);
//
//
//
//        }
//
//        mapFactory.stop_new_report = function(){
//            mapFactory.map.setCenter(mapFactory.start_position,15);
//
//            mapFactory.current_markers.setVisibility(true);
//        }
//        return mapFactory;
//    })
//*/
//
