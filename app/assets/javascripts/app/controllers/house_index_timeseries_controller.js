(function() {

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
    $scope.state = {showTable: false}
    $scope.options       = {neighborhood_id: $attrs.neighborhoodId, unit: "monthly", timeframe: "6", positive: true, potential: true, negative: true};
    $scope.refreshChartWithParams = function() {
      $scope.chartLoading = true;

      var ajax = $http({url: $attrs.path, method: "GET", params: $scope.options });
      ajax.success(function(response) {
        $scope.timeseries = response.timeseries

        if (response.timeseries.length <= 1) {
          $scope.noChartData = true;
        } else {
          $scope.noChartData = false;
          drawChart("timeseries-chart", response, $scope.options.unit)
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


    function drawChart(chartID, rawData, unit) {
      var dataTable    = new google.visualization.DataTable();

      // Create the type columns for the table.
      dataTable.addColumn("string", rawData.header.time);

      if ($scope.options.positive) {
        dataTable.addColumn("number", rawData.header.positive);
        dataTable.addColumn({type: 'string', role: 'annotation'});
        dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
      }

      if ($scope.options.potential) {
        dataTable.addColumn("number", rawData.header.potential);
        dataTable.addColumn({type: 'string', role: 'annotation'});
        dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
      }

      if ($scope.options.negative) {
        dataTable.addColumn("number", rawData.header.negative);
        dataTable.addColumn({type: 'string', role: 'annotation'});
        dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
      }

      // Iterate over the raw data.
      rawData = rawData.timeseries
      for (var i = 0; i < rawData.length; i++) {
        row = [
          rawData[i].date
        ]

        if ($scope.options.positive) {
          row = row.concat([
            rawData[i].positive.percent,
            customAnnotationForPercent(rawData[i].positive.percent, unit),
            customToolTipForData(rawData[i])
          ])
        }

        if ($scope.options.potential) {
          row = row.concat([
            rawData[i].potential.percent,
            customAnnotationForPercent(rawData[i].potential.percent, unit),
            customToolTipForData(rawData[i])
          ])
        }

        if ($scope.options.negative) {
          row = row.concat([
            rawData[i].negative.percent,
            customAnnotationForPercent(rawData[i].negative.percent, unit),
            customToolTipForData(rawData[i])
          ])
        }

        var rowIndex = dataTable.addRow(row)
        console.log(row)
        dataTable.setRowProperty(rowIndex, "rowData", rawData[i]);
      }


      var view    = new google.visualization.DataView(dataTable);
      var options = googleChartOptions(chartID, dataTable)
      var chart   = new google.visualization.ColumnChart(document.getElementById(chartID));
      chart.draw(view, options);
    }

    var googleChartOptions = function(chartID, data) {
      colors = []
      if ($scope.options.positive)
        colors.push("#e74c3c")
      if ($scope.options.potential)
        colors.push("#f1c40f")
      if ($scope.options.negative)
        colors.push("#2ecc71")


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
          bottom: 50,
          width: "90%",
          height: "100%"
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
        colors: colors,
        tooltip: { isHtml: true }
      };
      return options;
    }



    $scope.$watch("options.unit", function(newValue, oldValue) {
      if (newValue === oldValue)
        return;
      $scope.refreshChartWithParams();
    });

    $scope.$watch("options.positive", function(newValue, oldValue) {
      if (newValue === oldValue)
        return;
      $scope.refreshChartWithParams();
    });

    $scope.$watch("options.potential", function(newValue, oldValue) {
      if (newValue === oldValue)
        return;
      $scope.refreshChartWithParams();
    });

    $scope.$watch("options.negative", function(newValue, oldValue) {
      if (newValue === oldValue)
        return;
      $scope.refreshChartWithParams();
    });
  };

  angular.module("denguechat.controllers").controller("houseIndexTimeseriesCtrl", ["$scope", "$http", "$attrs", chartCtrl]);
})();
