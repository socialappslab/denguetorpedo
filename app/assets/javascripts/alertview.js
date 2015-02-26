$(document).ready(function() {
  // Track the new company creation.
  $("form").on("submit", function(event)
  {
    event.preventDefault();

    console.log("Starting file select...")

    $(".form-errors").hide();
    $(".form-errors p").text("");

    url    = $(this).attr("action")
    method = $(this).attr("method");


    // handleFileSelect("csv_report_csv", url, method, this)



    var fd = new FormData();

    form = $("form").serializeArray();
    console.log(form)
    for (var i = 0; i < form.length; i++)
    {
      fd.append( form[i].name, form[i].value )
    }
    input = document.getElementById("csv_report_csv")
    fd.append( 'csv_report[csv]', input.files[0] );

    $.ajax({
      url:  url,
      // data: $(this).serialize(),
      data: fd,
      contentType: false,
      type: method,
      processData: false,
      success: function(response) {
        console.log(response)
        if (response.error)
        {
          errors = response.error.join(", ");
          window.alert(errors);
        } else
        {
          window.alert("Success!");
        }


      },
      error: function(response) {
        console.log(response)
        if (response.responseText != "")
        {
          error = JSON.parse(response.responseText);
          $(".form-errors").show();
          $(".form-errors p").text(error.message);
        } else {
          window.alert("Something went wrong on our end. Please try again.")
        }
      },
      complete: function(response) {
        var button = $(event.target).find(":submit")
        button.find(".fa-refresh").hide();
        button.attr("disabled", false);
      }
    })



  })

})



function handleFileSelect(htmlID, url, method, form)
  {
    input = document.getElementById(htmlID)

    // parsed_csv

    if (!window.File || !window.FileReader || !window.FileList || !window.Blob) {
      alert('The File APIs are not fully supported in this browser.');
      return;
    }

    if (!input) {
      alert("Um, couldn't find the fileinput element.");
    }
    else if (!input.files) {
      alert("This browser doesn't seem to support the `files` property of file inputs.");
    }
    else if (!input.files[0]) {
      alert("Please select a file before clicking 'Load'");
    }
    else {
      console.log("Starting async file reader...");
      file = input.files[0];
      fr = new FileReader();

      fr.onload = function(event) {
        var csvData = event.target.result;
        $(".parsed_csv").val(csvData)

        console.log($(form).serialize());


        $.ajax({
          url:  url,
          data: $(form).serialize(),
          // contentType: false,
          type: method,
          // processData: false,
          success: function(response) {
            console.log(response)
            if (response.error)
            {
              errors = response.error.join(", ");
              window.alert(errors);
            } else
            {
              window.alert("Success!");
            }


          },
          error: function(response) {
            console.log(response)
            if (response.responseText != "")
            {
              error = JSON.parse(response.responseText);
              $(".form-errors").show();
              $(".form-errors p").text(error.message);
            } else {
              window.alert("Something went wrong on our end. Please try again.")
            }
          },
          complete: function(response) {
            var button = $(event.target).find(":submit")
            button.find(".fa-refresh").hide();
            button.attr("disabled", false);
          }
        })



        // data = $.csv.toArrays(csvData);
        // if (data && data.length > 0) {
        //   alert('Imported -' + data.length + '- rows successfully!');
        // } else {
        //     alert('No data to import!');
        // }
      };

      fr.readAsText(file);
      // fr.readAsDataURL(file);
    }
  }
