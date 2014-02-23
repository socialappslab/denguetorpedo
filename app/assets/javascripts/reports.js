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


angular.module('dengue_torpedo.controllers',['ngResource']).
        controller('ReportListController',function($scope,$resource){
            $scope.reports = {'test':'testing'};
            $resource('/reports_redesign.json').query({},function(data){
                $scope.reports = data;
            });

            $scope.gon = gon.angular;
            $scope.report_status = function(report){

            }
        });