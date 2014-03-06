$(document).ready(function() {

	$("select.elimination_type").change(function() {
		if ($(this).val() == "Outro tipo") {
			window.location = "/feedbacks/new?title=other_type";
		}
	});
	
	$("select.elimination_methods").each(function() {
		$(this).find("option").filter(function() {
			return $(this).text() == "Método de eliminação";
		}).prop("selected", true);
	});
	$("select.elimination_methods").change(function() {
		if ($(this).val() == "Outro método") {
			window.location.href = "/feedbacks/new?title=other_method";
		} else {
			$(this).parent().find("input#selected_elimination_method").val($(this).val());
		}
	});

});


angular.module('dengue_torpedo.controllers').
        //Controller for Report List
        controller('ReportListController',function($scope,$resource, Map){

            var allowed_time = 1000 * 60 * 60 * 48;  // milliseconds * sec * min * hour;
            var attempted_lookup = false;

            new_report_empty();


            $scope.reports = {};
            $scope.date = new Date();

            $resource('/reports_redesign.json').query({},function(data){
                $scope.reports = data;
            });

            $scope.create_new_report = function(){
                //Toggle report and call Map factory
                if($("#new_report_div").is(':hidden')){
                    $("#new_report_div").slideDown();
                    Map.start_new_report();
                }
                else {
                    $("#new_report_div").slideUp();
                    Map.stop_new_report();
                }
                new_report_empty();
            }


            $scope.display_method = function(name, points){
                return name + " (" + points + " pontos)";
            }


            $scope.report_expired = function(report){
                if(report.info.completed_at){
                    //report is expired if start_time + allowed_time < current_time
                    var start_time = new Date(report.info.completed_at);
                    return new Date(start_time.getTime() + allowed_time) < new Date().getTime();

                }

            }

            $scope.submit_report= function(form){
                if(form.$valid){
                    $scope.new_report.location.address = $scope.new_report.location.street_type +
                                                         " " + $scope.new_report.location.street_name +
                                                         " " + $scope.new_report.location.street_number +
                                                         " " + $scope.new_report.location.neighborhood;

                    $scope.new_report.info.completed_at = new Date();

                    $.ajax({
                        url: '\submit_report',
                        type: 'POST',
                        data: $scope.new_report,
                        success:function(data){
                                $scope.new_report.info.completed_at = data.completed_at;
                                $scope.new_report.info.reporter_name = data.reporter_name;
                                $scope.reports.splice(0,0,$scope.new_report);
                                new_report_empty();
                                $("#new_report_div").hide();
                                $scope.$apply();
                        },
                        error:function(data){
                            console.log("There was an error :(");
                        }

                    });

              }
            }

            $scope.time_left =function(report){
                var start_time = new Date(report.info.completed_at);
                return start_time.getTime() + allowed_time;
            }

            //create blank new report
            function new_report_empty(){

                $scope.new_report = {
                    'info':{
                        'report_description':'',
                        'elimination_type':'',
                        'created_at':''},
                    'location':{
                        'address':'',
                        'street_type':'',
                        'street_name':'',
                        'street_number':'',
                        'neighborhood':''},
                    'img':{
                        'before':''}
                };
            }


            //watch if address fields are all full
//            $("#address_field :input").change(function(e){
//                //look at all values, if none are blank, attempt lookup
//                var count = 0;
//                var query = "";
//                angular.forEach($scope.new_report.location, function(k,v){
//                    query += v + "+";
//                    if(v == "")
//                        count++;
//                })
//
//                if(count == 0)
//                {
//                    query = query.slice(0,query.length - 1);
//                    console.log("count called, val = " + count);
//                    //check if attempt has been made (? might want to redo)
//                    if(!attempted_lookup){
//                        attempted_lookup = true;
//                        $resource("http://nominatim.openstreetmap.org/search?q=mare+rio+de+janeiro&format=json&polygon=1"
//                    }
//
//                }
//            });


        });