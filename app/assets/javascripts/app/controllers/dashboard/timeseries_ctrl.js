var ctrl = function ($scope, $http, $attrs) {
  $scope.loading       = false;
  $scope.neighborhoods = [];
  $scope.timeseries    = [];
  $scope.options       = {unit: "monthly", timeframe: "6"};
  $scope.customDateRange = false;
  $scope.chartLoading = false;
  $scope.noChartData  = false;
  $scope.state = {chart: false}


  var prepareParams = function() {
    // General params.
    var params = {
      neighborhoods: JSON.stringify($scope.neighborhoods),
      unit: $scope.options.unit
    };

    // Send specific params depending on what the user is viewing currently.
    if ($scope.customDateRange) {
      params.custom_start_month = $scope.options.customStartMonth,
      params.custom_start_year = $scope.options.customStartYear,
      params.custom_end_month = $scope.options.customEndMonth,
      params.custom_end_year = $scope.options.customEndYear
    } else {
      params.timeframe = $scope.options.timeframe
    }

    return params;
  }

  $scope.generatePreview = function() {
    $scope.loading     = true;
    $scope.serverError = false;
    $scope.serverErrorMessage = null;
    $scope.timeseries    = [];

    var params = prepareParams()

    var promise   = $http({
      url: $attrs.path,
      method: "GET",
      params: params
    });
    promise = promise.then(function(response) {
      $scope.timeseries = response.data.timeseries;
      if ($scope.timeseries.length === 0)
        $scope.serverErrorMessage = "Sin datos";

      if (response.data.length <= 1) {
        $scope.noChartData = true;
      } else {
        $scope.state.chart = true
        $scope.noChartData = false;
        drawChart("timeseries-chart", response.data, $scope.options.unit)
      }


    }, function(response) {
      $scope.serverError = true;
      $scope.serverErrorMessage = response.data.message;
    })

    promise.finally(function(response) {
      $scope.loading = false;
    })
  }

  $scope.generateCsv = function() {
    $scope.loading     = false;
    $scope.serverError = false;
    $scope.serverErrorMessage = null;
    var params = prepareParams()

    window.location.href = $attrs.path + ".csv?" + $.param(params)
  }


  $scope.toggleNeighborhood = function(id) {
    index = $scope.neighborhoods.indexOf(id)
    if (index === -1)
      $scope.neighborhoods.push(id)
    else {
      $scope.neighborhoods.splice(index, 1)
    }
  }



  var googleChartOptions = function(chartID, data) {
    var options =  {
      annotations: {
        alwaysOutside: true
      },
      // width: 500,
      // height: 350,
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
      colors: ["#e74c3c", "#f1c40f", "#2ecc71"],
      tooltip: { isHtml: true }
    };
    return options;
  }

  function drawChart(chartID, rawData, unit) {
    var dataTable    = new google.visualization.DataTable();

    // Create the type columns for the table.
    var columnNames = rawData.header;
    dataTable.addColumn("string", columnNames[0])
    for (var i = 1; i < columnNames.length; i++) {
      dataTable.addColumn("number", columnNames[i]);
      dataTable.addColumn({type: 'string', role: 'annotation'});
      dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
    }

    // Iterate over the raw data.
    rawData = rawData.timeseries
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




    // $scope.refreshChartWithParams = function() {
    //   $scope.chartLoading = true;
    //
    //   var params = {};
    //   params.neighborhood_id =  $attrs.neighborhoodId;
    //   params.percentages     = $scope.chartOptions.percentages;
    //
    //   var ajax = $http({url: $attrs.path, method: "GET", params: params });
    //   ajax.success(function(response) {
    //     if (response.data.length <= 1) {
    //       $scope.noChartData = true;
    //     } else {
    //       $scope.noChartData = false;
    //       drawChart("timeseries-chart", response.data, $scope.chartOptions.percentages)
    //     }
    //   });
    //   ajax.error(function(response) {
    //     $scope.chartLoading = false;
    //   });
    //   ajax.then(function(response) {
    //     $scope.chartLoading = false;
    //   });
    // }
    //
    // $scope.refreshChartWithParams();
    // $scope.$watch("chartOptions.percentages", function(newValue, oldValue)
    // {
    //   if (newValue === oldValue)
    //     return;
    //   $scope.refreshChartWithParams();
    // });
    //


};


angular.module("denguechat.controllers").controller("dashboardTimeSeriesCtrl", ["$scope", "$http", "$attrs", ctrl]);
