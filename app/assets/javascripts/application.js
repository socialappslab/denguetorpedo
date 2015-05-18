// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require_self
//= require "feed-interactions"
//= require angular
//= require angular-route



window.denguechat = {};

$(document).ready(function()
{
  $(".submit-button").on("click", function(e)
  {
    var button = $(e.currentTarget);
    button.find(".fa-refresh").show();
    button.attr("disabled", true);
    $(e.currentTarget.form).trigger("submit")
    return true;
  });

  //---------------------------------------------------------------------------

  $(".delete-resource-button").click(function(event){
    event.preventDefault();

    var choice = confirm($(this).data("confirm"));
    if (choice == false)
      return

    // Trim the count of the text
    $.ajax({
      url: $(this).data("path"),
      type: "DELETE",
      success : function(data){
        $(event.currentTarget).parents('.feed-item').remove();
        $(event.currentTarget).parents('.report').remove();

      }
    })
  });
})
