service = ($resource) ->
  return api: (path) ->
    return $resource path, {}, {}
angular.module('denguechat.services').factory("Location", ["$resource", service]);
