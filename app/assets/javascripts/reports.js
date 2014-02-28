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

            $scope.new_report = false;

            $scope.reports = {};
            $scope.date = new Date();//.getTime();

            $resource('/reports_redesign.json').query({},function(data){
                $scope.reports = data;
                console.log($scope.reports);
            });

            $scope.create_new_report = function(){
                $("#new_report").slideDown();
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


        });