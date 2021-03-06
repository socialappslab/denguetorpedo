var postCtrl = function ($scope, $http, $attrs) {
  $scope.posts        = []
  $scope.noMoreData   = false;
  $scope.usernames    = angular.fromJson( $attrs.usernames );

  var loadPost = function() {
    $scope.dataLoading  = true;
    $scope.errorMessage = false;

    var promise = $http({url: $attrs.postPath, method: "GET"});
    promise = promise.then(function(response) {
      $scope.posts         = [response.data];
      $scope.errorMessage = false;
    }, function(response) {
      $scope.errorMessage = true;
    })
    promise.finally(function(response) {
      $scope.dataLoading  = false;
    });
  }

  loadPost()

  $scope.createPost = function(post) {
    // Disable the submit button for new-post directive.
    $scope.submitButtonDisabled = true;

    post["compressed_photo"] = $(".compressed_photo").val();
    post["neighborhood_id"] = $attrs.neighborhoodId;
    var ajax = $http.post("/api/v0/posts/", {"post": post});
    ajax.success(function(data) {
      post.content = ""
      $(".preview").parent().html("<img class='preview'>")
      $(".compressed_photo").val("")
      $scope.submitButtonDisabled = false;
      $scope.posts.unshift(data)
    })

    ajax.error(function(data) {
      $scope.submitButtonDisabled = false;
    })
  }

  $scope.createComment = function(post, comment) {
    // Disable the submit button for new-post directive.
    $scope.submitButtonCommentDisabled = true;

    var ajax = $http.post("/api/v0/posts/" + post.id + "/comments", {"comment": comment});
    ajax.success(function(data) {
      comment.content = ""
      // $scope.submitButtonCommentDisabled = false;
      post.comments.push(data)
    })

    ajax.error(function(data) {
      // $scope.submitButtonCommentDisabled = false;
    })
  }


  // TODO: This is a bit confusing as it triggers the file upload, which has
  // an attribute directive defined on change event. Confusing code!
  $scope.triggerFileInput = function() {
    $("input[type='file']").trigger("click")
  }

  $scope.updateLikesCounter = function(post) {
    var ajax = $http.post(post.actions.like, {"count": post.likes_count});
    ajax.success(function(data) {
      post.likes_count = data.count;
      post.liked       = data.liked;
    })
  }

  $scope.updateCommentLikesCounter = function(comment) {
    // TODO: Use Rails routes.
    var ajax = $http.post("/api/v0/comments/" + comment.id + "/like", {"count": comment.likes_count});
    ajax.success(function(data) {
      comment.likes_count = data.count;
      comment.liked       = data.liked;
    })
  }

  $scope.deletePost = function(post) {
    var answer = window.confirm("¿Estas seguro?");
    if (answer !== true)
      return false;

    $scope.deleteRequestSubmitted = true;

    var ajax = $http.delete(post.actions.delete);
    ajax.success(function(data) {
      var index = $scope.posts.indexOf(post);
      $scope.posts.splice(index, 1);
    })
    ajax.error(function(data) {
      alert(data.message);
    })
    ajax.then(function(data) {
      $scope.deleteRequestSubmitted = false;
    })
  }

  $scope.deleteComment = function(post, comment) {
    var answer = window.confirm("¿Estas seguro?");
    if (answer !== true)
      return false;

    $scope.deleteRequestSubmitted = true;

    var ajax = $http.delete(comment.actions.delete);
    ajax.success(function(data) {
      var index = post.comments.indexOf(comment);
      post.comments.splice(index, 1);
    })
    ajax.error(function(data) {
      alert(data.message);
    })
    ajax.then(function(data) {
      $scope.deleteRequestSubmitted = false;
    })
  }
};





// We use inline annotation to declare services in order to bypass
// errors when JS gets minified:
// https://docs.angularjs.org/tutorial/step_05
var postController = angular.module("denguechat.controllers").controller("postCtrl", ["$scope", "$http", "$attrs", postCtrl]);
