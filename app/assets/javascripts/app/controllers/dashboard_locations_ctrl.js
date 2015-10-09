var ctrl = function ($scope, $http, $attrs) {
  $scope.loading   = false;
  $scope.addresses = [];

  $scope.searchLocations = function() {
    $scope.loading     = true;
    $scope.serverError = false;
    $scope.serverErrorMessage = null;

    var promise   = $http({url: $attrs.path, method: "GET", params: {addresses: $scope.addresses} });
    promise = promise.then(function(response) {
      $scope.locations = response.data.locations;
    }, function(response) {
      $scope.serverError = true;
      $scope.serverErrorMessage = response.data.message;
    })

    promise.finally(function(response) {
      $scope.loading = false;
    })
  }
};


angular.module("denguechat.controllers").controller("dashboardLocationsCtrl", ["$scope", "$http", "$attrs", ctrl]);
