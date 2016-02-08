directive = () ->
  return {
    restrict: "A",
    link: (scope, element, attrs) ->
      post = scope.post

      title = post.user.display_name + " en DengueChat"
      description = "\"" + post.content + "\""

      element.on "click", (event) ->
        FB.ui(
          method: 'feed',
          link: "https://www.denguechat.com" + post.path,
          # picture: post.photo,
          name: title,
          description: description
        , (response) ->
          console.log(response)
          # GET THE POST ID AND UPDATE facebook_post_id column of the post.
        );
  }

angular.module("denguechat.directives").directive("shareToFacebook", [directive]);
