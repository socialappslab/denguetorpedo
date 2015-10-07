// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require_self
//= require "feed-interactions"
//= require angular
//= require angular-sanitize
//= require angular-cookies
//= require "app/app"
//= require "app/controllers/post_controller"
//= require "app/controllers/chart_controller"
//= require "app/controllers/house_index_timeseries_controller"
//= require "app/controllers/location_controller"
//= require "app/controllers/heatmap_controller"
//= require "app/controllers/csv_verify_controller"
//= require "app/controllers/city_controller"
//= require "app/controllers/green_locations_chart_controller"
//= require "app/controllers/csv_batch_upload_controller"
//= require "app/directives/remote-link"
//= require "app/directives/remote-submit"
//= require "app/directives/compress-image"


//= require "jquery/caret-min"
//= require "jquery/atwho-min"



window.denguechat = {};

$(document).ready(function()
{
  $(".notifications-toggle").on("click", function(e) {
    $(".notifications").toggle();
  })

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
