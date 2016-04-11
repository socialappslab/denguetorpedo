service = ($resource) ->
  return $resource("/api/v0/users/:id/scores", {id:'@id'})
angular.module('denguechat.services').factory("User", ["$resource", service]);
