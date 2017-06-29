angular.module('denguechat.services').factory("TimeSeries", ["$resource", ($resource) ->
  return $resource "/api/v0/timeseries", null, {}
]);
