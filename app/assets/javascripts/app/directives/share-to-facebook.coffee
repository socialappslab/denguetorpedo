directive = () ->
  return {
    restrict: "A",
    link: (scope, element, attrs) ->
      post = angular.fromJson(attrs.post)

      title = post.user.display_name + " en DengueChat"

      if post.content
        description = "\"" + String(post.content).replace(/<[^>]+>/gm, '') + "\""
      else
        description = null

      element.on "click", (event) ->
        FB.ui(
          method: 'feed',
          link: "https://www.denguechat.com" + post.path,
          picture: post.photo,
          name: title,
          description: description
        , (response) ->
          console.log(response)
          analytics.track("Shared post to Facebook", {id: post.id}) if response
        );
  }

angular.module("denguechat.directives").directive("shareToFacebook", [directive]);
