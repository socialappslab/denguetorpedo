
var directive = function($http){
  return {
    restrict: "A",
    link: function(scope, element, attrs) {
      element.on("submit", function(event) {
        event.preventDefault();

        element.find(".fa-spin").show();
        element.find(":submit").attr("disabled", true)

        var fd   = new FormData();
        var form = element.serializeArray();
        for (var i = 0; i < form.length; i++) {
          fd.append( form[i].name, form[i].value );
        }

        $.ajax({
          url:  event.currentTarget.action,
          type: event.currentTarget.method,
          data: fd,
          contentType: false,
          processData: false,
          success: function(response) {
            window.alert("Éxito!");
            if (response.reload)
              window.location.reload();
            if (response.redirect_path)
              window.location.href = response.redirect_path;
          },

          error: function(response) {
            alert(response.responseJSON.message);
          },

          complete: function(response) {
            element.find(".fa-spin").hide();
            element.find(":submit").attr("disabled", false)

          }
        })
      })
    }
  }
}

angular.module("denguechat.directives").directive("remoteSubmit", ["$http", directive]);
