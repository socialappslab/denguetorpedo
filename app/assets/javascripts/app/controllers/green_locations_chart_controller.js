var chartCtrl = function ($scope, $http, $cookies, $attrs) {
  $scope.chartLoading = false;
  $scope.noChartData  = false;

  $scope.refreshChartWithParams = function() {
    $scope.chartLoading = true;

    var ajax = $http({url: $attrs.greenLocationsPath, method: "GET"});
    ajax.success(function(response) {
      $scope.chartLoading = false;
      if (response.green_locations.length === 0) {
        $scope.noChartData = true;
      } else {
        $scope.noChartData = false;
        drawChart("green-locations-chart-minor", response.green_locations);
        drawChart("green-locations-chart-major", response.green_locations);
      }
    });
    ajax.error(function(response) {
      $scope.chartLoading = false;
    });
    ajax.then(function(response) {
      $scope.chartLoading = false;
    });
  }

  $scope.refreshChartWithParams();

  $scope.showGreenLocationsChartModal = function() {
    $('#green-locations-chart-modal').modal('show');
  }
};



// We use inline annotation to declare services in order to bypass
// errors when JS gets minified:
// https://docs.angularjs.org/tutorial/step_05
angular.module('dengueChatApp').controller("greenLocationsChartCtrl", ["$scope", "$http", "$cookies", "$attrs", chartCtrl]);




function drawChart(chartID, data) {
  var dataTable = new google.visualization.DataTable();
  var dateColumn = dataTable.addColumn("string", "Semana")
  var numberColumn = dataTable.addColumn("number", "Casas Verdes")
  dataTable.addColumn({'type': 'string', 'role': 'tooltip'})
  dataTable.addColumn({type: 'number', role: 'annotation'});

  for (var i = 0; i < data.length; i++) {
    var tooltipText = data[i].week + ": " + data[i].count;
    dataTable.addRow([data[i].week, data[i].count, tooltipText, data[i].count])
  }

  var element = document.getElementById(chartID);
  var options = {
    chartArea: {
      left: 50,
      right: 50,
      top: 0,
      bottom: 0,
      width: "100%",
      height: "90%"
    },
    colors: ["#5cb85c"],
    hAxis: {
      gridlines: {
        color: "transparent"
      }
    },
    vAxis: {
      baselineColor: '#fff',
      gridlineColor: '#fff',
      textPosition: 'none',
      minValue: 0,
      gridlines: {
        color: "transparent"
      }
    }
  };

  var chart = new google.visualization.ColumnChart(document.getElementById(chartID));
  var view = new google.visualization.DataView(dataTable);
  chart.draw(view, options);
}
