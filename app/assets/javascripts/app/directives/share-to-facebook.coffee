directive = () ->
  return {
    restrict: "A",
    link: (scope, element, attrs) ->
      post = angular.fromJson(attrs.post)

      title = post.user.display_name + " en DengueChat"

      if post.content
        description_var = "\"" + String(post.content).replace(/<[^>]+>/gm, '') + "\""
      else
        description_var = null

      localizacion = String(post.user.neighborhood.geographical_display_name).split ','

      web = null

      if localizacion[1].replace(" ","") == "Armenia"
        web = "https://www.denguechat.org/cities/8"
      
      if localizacion[1].replace(" ","") == "Managua"
        web = "https://www.denguechat.org/cities/4"

      if localizacion[1].replace(" ","") == "Asunción"
        web = "https://www.denguechat.org/cities/9"

      if web == null
        web = "https://www.denguechat.org/"

      console.log(web)

      element.on "click", (event) ->
        FB.ui(
          method: 'feed',
          link: web,
          name: "Conoce más sobre DengueChat",
          picture: post.photo
          description: description_var
        , (response) ->
          console.log(response)
          analytics.track("Shared post to Facebook", {id: post.id}) if response
        );
  }

angular.module("denguechat.directives").directive("shareToFacebook", [directive]);
