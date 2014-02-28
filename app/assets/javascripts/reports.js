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

angular.module('dengue_torpedo.controllers',['ngResource', 'timer']).
        //Controller for Report List
        controller('ReportListController',function($scope,$resource){
            allowed_time = 1000 * 60 * 60 * 48;  // milliseconds * sec * min * hour;
            new_report_empty();


            $scope.reports = {};
            $scope.date = new Date();//.getTime();

            $resource('/reports_redesign.json').query({},function(data){
                $scope.reports = data;
            });

            $scope.create_new_report = function(){
                $("#new_report").slideDown();
            }

            $scope.submit_report= function(){
                $scope.new_report.location.address = $scope.new_report.info.street_type +
                                                     " " + $scope.new_report.info.street_name +
                                                     " " + $scope.new_report.info.street_number +
                                                     " " + $scope.new_report.info.neighborhood;

//                var data = new FormData($('#new_report_form')[0]);
//
//                $.ajax({
//                    url: '\submit_report',
//                    type: 'POST',
//                    data: data,
//                    success:function(data){
//                        alert(data['status']);
//                        if(data['status'] == 'success')
//                            $scope.reports.splice(0,0,$scope.new_report);
//                    }
//
//                });

                $scope.reports.splice(0,0,$scope.new_report);
                new_report_empty();

              $("#new_report").hide();
            }





            $scope.time_left =function(report){
                var start_time = new Date(report.info.completed_at);
                return start_time.getTime() + allowed_time;
            }

            $scope.report_expired = function(report){
                if(report.info.completed_at){
                    //report is expired if start_time + allowed_time < current_time
                    var start_time = new Date(report.info.completed_at);
                    return new Date(start_time.getTime() + allowed_time) < new Date().getTime();

                }

            }


            function new_report_empty(){

                $scope.new_report = {'info':{'street_type':'',
                    'street_name':'',
                    'street_number':'',
                    'neighborhood':'',
                    'report_description':'',
                    'elimination_type':''},
                    'location':{'address':''}
                };
            }


        });