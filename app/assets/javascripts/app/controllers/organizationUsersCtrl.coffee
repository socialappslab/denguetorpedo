angular.module("denguechat.controllers").controller("organizationUsersCtrl", ["$scope", "$http", "$attrs", "User", "usersInit", ($scope, $http, $attrs, User, usersInit) ->
  $scope.users = []
  $scope.state = {loading: false}

  $scope.options = usersInit


  $scope.loadUsers = () ->
    $scope.state.loading = true

    req = User.get({city_id: $scope.options.city_id, neighborhood_id: $scope.options.neighborhood_id}).$promise
    req.then  (res) ->
      $scope.memberships = res.memberships
    req.catch   (res) -> $scope.$emit(denguechat.error, res)
    req.finally (res) -> $scope.state.loading = false;
  $scope.loadUsers()

  $scope.changeRole = (membership) ->
    $scope.state.loading = true

    req = User.membership({id: membership.user_id, membership: membership}).$promise
    req.then  (res) ->
      $scope.$emit(denguechat.success, res)
    req.catch   (res) -> $scope.$emit(denguechat.error, res)
    req.finally (res) -> $scope.state.loading = false;


]);
