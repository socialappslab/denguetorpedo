var ctrl = function ($scope, $http, $attrs) {
  $scope.loading       = false;
  $scope.neighborhoods = [];
  $scope.timeseries    = [];
  $scope.options       = {unit: "monthly", timeframe: "6"};
  $scope.customDateRange = false;

  $scope.generatePreview = function() {
    $scope.loading     = true;
    $scope.serverError = false;
    $scope.serverErrorMessage = null;
    $scope.timeseries    = [];

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

    var promise   = $http({
      url: $attrs.path,
      method: "GET",
      params: params
    });
    promise = promise.then(function(response) {
      $scope.timeseries = response.data;
      if ($scope.timeseries.length === 0)
        $scope.serverErrorMessage = "Sin datos";

    }, function(response) {
      $scope.serverError = true;
      $scope.serverErrorMessage = response.data.message;
    })

    promise.finally(function(response) {
      $scope.loading = false;
    })
  }

  $scope.toggleNeighborhood = function(id) {
    index = $scope.neighborhoods.indexOf(id)
    if (index === -1)
      $scope.neighborhoods.push(id)
    else {
      $scope.neighborhoods.splice(index, 1)
    }
  }
};


angular.module("denguechat.controllers").controller("dashboardTimeSeriesCtrl", ["$scope", "$http", "$attrs", ctrl]);
