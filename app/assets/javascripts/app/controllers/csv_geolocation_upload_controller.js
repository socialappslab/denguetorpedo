var ctrl = function ($scope, $http, $attrs) {
  $scope.csv_previews = [];

  $scope.geolocationUpload = function(event) {
    console.log(event)
    // Interrupt and reset all past errors.
    event.preventDefault();
    $(".form-errors").hide();
    $(".form-errors p").text("");

    // Construct the form using FormData to accommodate uploading
    // CSV files.
    var fd    = new FormData();
    for (var i = 0; i < $scope.csv_previews.length; i++) {
      fd.append( "multiple_csv[]", $scope.csv_previews[i] );
    }

    // Perform the AJAX request.
    url    = event.currentTarget.action;
    method = event.currentTarget.method;
    $.ajax({
      url:  url,
      type: method,
      data: fd,
      contentType: false,
      processData: false,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      success: function(response) {
        console.log(response)
        if (response.error)
        {
          var error = response.error.join(", ");
          $(".form-errors").show();
          $(".form-errors p").text(error);
        } else {
          window.alert("Éxito!");
          window.location.href = response.redirect_path;
        }
      },

      error: function(response) {
        console.log(response.responseJSON)
        if (response.responseJSON)
        {
          $(".form-errors").show();
          $(".form-errors p").text(response.responseJSON.message);
        }
        else
          window.alert("Something went wrong on our end. Please try again.")
      },

      complete: function(response) {
        var button = $(event.target).find(":submit")
        button.find(".fa-refresh").hide();
        button.attr("disabled", false);
      }
    })



  }

};


var directive = function(){
  console.log("directive-");
  return {
    restrict: "A",
    scope: false,
    link: function(scope, element, attrs) {
      element.on("change", function(event) {
        var input = document.getElementById("multiple_csv");
        scope.csv_previews = [];
        for (var i = 0; i < input.files.length; i++) {
          console.log("file"+i+" : "+input.file[i])
          scope.csv_previews.push(input.files[i])
        }

        // Call $apply() to invoke a digest cycle. Why is this not done automatically?
        // Because this is an event handler called outside of angular, and Angular doesn't
        // know about these view changes.
        // http://stackoverflow.com/questions/16066170/angularjs-directives-change-scope-not-reflected-in-ui
        scope.$apply();
      })
    }
  }
}


// We use inline annotation to declare services in order to bypass
// errors when JS gets minified:
// https://docs.angularjs.org/tutorial/step_05
angular.module("denguechat.controllers").controller("csvGeolocationUploadCtrl", ["$scope", "$http", "$attrs", ctrl]);
angular.module("denguechat.directives").directive("showCsvPreview", directive);
