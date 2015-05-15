var postListCtrl = function ($scope, $http) {
  var ajax = $http.get("/api/v0/posts.json");

  ajax.success(function(data) {
    $scope.posts = data.posts;
  });
  ajax.error(function(response) {
    $("#newsfeed .error-message").show();
  })
  ajax.then(function() {
    $("#newsfeed .loading-spinner").hide();
  })
};


// We use inline annotation to declare services in order to bypass
// errors when JS gets minified:
// https://docs.angularjs.org/tutorial/step_05
var postsController = angular.module('DCPostListCtrl', []);

postsController.controller("DCPostListCtrl", ["$scope", "$http", postListCtrl]);
