(function() {

  var googleChartOptions = function(chartID, data) {
    var options =  {
      annotations: {
        alwaysOutside: true
      },
      width: 500,
      height: 350,
      chartArea: {
        left: 50,
        right: 50,
        top: 50,
        bottom: 0,
        width: "90%",
        height: "70%"
      },
      hAxis: {
        showTextEvery: parseInt(data.getNumberOfRows() / 4)
      },
      vAxis: {
        format: "#\'%\'"
      },
      legend: {
        position: "none",
        alignment: "start",
        textStyle: {
          fontSize: "15"
        }
      },
      colors: ["#e74c3c", "#f1c40f", "#2ecc71"],
      tooltip: { isHtml: true }
    };
    return options;
  }

  function drawChart(chartID, rawData, unit) {
    var dataTable    = new google.visualization.DataTable();

    // Create the type columns for the table.
    var columnNames = rawData.shift();
    dataTable.addColumn("string", columnNames[0])
    for (var i = 1; i < columnNames.length; i++) {
      dataTable.addColumn("number", columnNames[i]);
      dataTable.addColumn({type: 'string', role: 'annotation'});
      dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
    }

    // Iterate over the raw data.
    for (var i = 0; i < rawData.length; i++) {
      var rowIndex = dataTable.addRow( [
        rawData[i].date,
        rawData[i].positive.percent,
        customAnnotationForPercent(rawData[i].positive.percent, unit),
        customToolTipForData(rawData[i]),
        rawData[i].potential.percent,
        customAnnotationForPercent(rawData[i].potential.percent, unit),
        customToolTipForData(rawData[i]),
        rawData[i].negative.percent,
        customAnnotationForPercent(rawData[i].negative.percent, unit),
        customToolTipForData(rawData[i])
      ] )
      dataTable.setRowProperty(rowIndex, "rowData", rawData[i]);
    }


    var view    = new google.visualization.DataView(dataTable);
    var options = googleChartOptions(chartID, dataTable)
    var chart   = new google.visualization.ColumnChart(document.getElementById(chartID));
    chart.draw(view, options);
  }

  // Let's not display the annotations for now.
  var customAnnotationForPercent = function(percent, unit) {
    if (unit == "monthly")
      return String(percent) + "%";
    else
      return "";
  }

  var customToolTipForData = function(data) {
    var s = "<table class = 'table'><tbody>"
    s += "<tr><td>Fecha de visita</td><td>" + data.date + "</td></tr>";
    s += "<tr><td>Lugares visitados</td><td>" + data.total.count + "</td></tr>"
    s += "<tr><td>Lugares positivos</td><td>" + data.positive.count + " (" + data.positive.percent + "%)</td></tr>"
    s += "<tr><td>Lugares potenciales</td><td>" + data.potential.count + " (" + data.potential.percent + "%)</td></tr>"
    s += "<tr><td>Lugares negativos</td><td>" + data.negative.count + " (" + data.negative.percent + "%)</td></tr>"
    s += "</tbody></table>"
    return s;
  }


  var chartCtrl = function ($scope, $http, $attrs) {
    $scope.chartLoading = false;
    $scope.noChartData  = false;
    $scope.chartOptions = {"percentages": "monthly"}

    $scope.refreshChartWithParams = function() {
      $scope.chartLoading = true;

      var params = {};
      params.neighborhood_id =  $attrs.neighborhoodId;
      params.percentages     = $scope.chartOptions.percentages;

      var ajax = $http({url: $attrs.path, method: "GET", params: params });
      ajax.success(function(response) {
        if (response.data.length <= 1) {
          $scope.noChartData = true;
        } else {
          $scope.noChartData = false;
          drawChart("timeseries-chart", response.data, $scope.chartOptions.percentages)
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
    $scope.$watch("chartOptions.percentages", function(newValue, oldValue)
    {
      if (newValue === oldValue)
        return;
      $scope.refreshChartWithParams();
    });
  };

  angular.module("denguechat.controllers").controller("houseIndexTimeseriesCtrl", ["$scope", "$http", "$attrs", chartCtrl]);
})();
