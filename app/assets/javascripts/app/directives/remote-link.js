var remoteLinkDirective = function($http){
  return {
    restrict: "A", // Restrict the template to being called only when using <h1 remote-link> HTML element.
    link: function(scope, element, attrs) {
      element.on("click", function(event) {
        event.preventDefault();

        // If a prompt is present, let's go ahead and present.
        if (attrs.prompt) {
          var answer = window.confirm(attrs.prompt)
          if (answer !== true)
            return false;
        }

        element.toggleClass("disabled")

        var ajax = $http({url: event.currentTarget.href, method: attrs.method});
        ajax.success(function(response) {
          alert("Success!");

          if (response.redirect_path)
            window.location.href = response.redirect_path;

          if (response.reload || attrs.reload)
            window.location.reload();
        });
        ajax.error(function(response) {
          alert(response.message);
        });
        ajax.then(function(response) {
          element.toggleClass("disabled")
        });

        return false;
      })
    }
  }
}

angular.module("denguechat.directives").directive("remoteLink", ["$http", remoteLinkDirective]);
