(function() {

  function drawChart(chartID, data) {
    var dataTable = new google.visualization.DataTable();
    var dateColumn = dataTable.addColumn("string", "Semana")
    var numberColumn = dataTable.addColumn("number", "Casas Verdes")
    dataTable.addColumn({'type': 'string', 'role': 'tooltip'})
    dataTable.addColumn({type: 'number', role: 'annotation'});

    for (var i = 0; i < data.length; i++) {
      var tooltipText = data[i].start_week + " a " + data[i].end_week + " : " + data[i].count + " casas verdes";
      dataTable.addRow([data[i].start_week, data[i].count, tooltipText, data[i].count])
    }

    var element = document.getElementById(chartID);
    var options = {
      width: element.offsetWidth,
      chartArea: {
        width: "100%",
        height: "80%",
        left: 25
      },
      colors: ["#5cb85c"],
      hAxis: {
        title: "Semana",
        gridlines: {
          color: "transparent"
        }
      },
      vAxis: {
        title: "Casas Verdes",
        textPosition: 'in',
        minValue: 0
      },
      legend: "none"
    };

    if (chartID == "green-locations-chart-minor")
      options.hAxis.textPosition = 'none';


    var chart = new google.visualization.ColumnChart(document.getElementById(chartID));
    var view = new google.visualization.DataView(dataTable);
    chart.draw(view, options);
  }


  var ctrl = function ($scope, $http, $cookies, $attrs) {
    $scope.chartLoading = false;
    $scope.noChartData  = false;
    $scope.city         = angular.fromJson($attrs.city);

    $scope.refreshChart = function(chartID) {
      $scope.chartLoading = true;

      var ajax = $http({url: $attrs.greenLocationsPath, method: "GET", params: {"city": $scope.city.id}});
      ajax.success(function(response) {
        $scope.chartLoading = false;
        if (response.green_locations.length === 0) {
          $scope.noChartData = true;
        } else {
          $scope.noChartData = false;
          drawChart(chartID, response.green_locations);
        }
      });
      ajax.error(function(response) {
        $scope.chartLoading = false;
      });
      ajax.then(function(response) {
        $scope.chartLoading = false;
      });
    }

    $scope.refreshChart("green-locations-chart-minor");

    // $scope.showGreenLocationsChartModal = function() {
    //   $('#green-locations-chart-modal').modal('show');
    //   $scope.refreshChart("green-locations-chart-major");
    // }
  }



  // We use inline annotation to declare services in order to bypass
  // errors when JS gets minified:
  // https://docs.angularjs.org/tutorial/step_05
  angular.module("denguechat.controllers").controller("greenLocationsChartCtrl", ["$scope", "$http", "$cookies", "$attrs", ctrl]);

}());
