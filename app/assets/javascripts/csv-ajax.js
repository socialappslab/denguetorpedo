$(document).ready(function() {
  $("form").on("submit", function(event)
  {
    // Interrupt and reset all past errors.
    event.preventDefault();
    $(".form-errors").hide();
    $(".form-errors p").text("");


    // Construct the form using FormData to accommodate uploading
    // CSV files.
    var fd   = new FormData();
    var form = $("form").serializeArray();
    for (var i = 0; i < form.length; i++)
      fd.append( form[i].name, form[i].value )

    var input = document.getElementById("csv_report_csv");
    if (input.files[0])
      fd.append( 'csv_report[csv]', input.files[0] );

    // Perform the AJAX request.
    url    = $(this).attr("action")
    method = $(this).attr("method");
    $.ajax({
      url:  url,
      type: method,
      data: fd,
      contentType: false,
      processData: false,
      success: function(response) {
        if (response.error)
        {
          var error = response.error.join(", ");
          $(".form-errors").show();
          $(".form-errors p").text(error);
        } else {
          if (typeof window.denguechat.responseCallback == "function")
            window.denguechat.responseCallback(response);
          else
            window.alert("Success!");
        }
      },

      error: function(response) {
        if (response.responseText != "")
        {
          error = JSON.parse(response.responseText);
          $(".form-errors").show();
          $(".form-errors p").text(error.message);
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
  })
})
