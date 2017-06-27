angular.module('denguechat.services').factory("User", ["$resource", ($resource) ->
  return $resource "/api/v0/users", {}, {
    "scores": {method: "GET", url: "/api/v0/users/:id/scores", params: {id: "@id"}},
    "membership": {method: "PUT", url: "/api/v0/users/:id/membership", params: {id: "@id"}}
  }
]);
