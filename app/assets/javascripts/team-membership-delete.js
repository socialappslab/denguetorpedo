$(document).ready(function()
{
  $(".leave-team-button").click(function(event){
    event.preventDefault();

    var choice = confirm($(this).data("confirm"));
    if (choice == false)
      return

    // Trim the count of the text
    $.ajax({
      url: $(this).data("path"),
      type: "POST",
      success : function(data){
        $(event.currentTarget).parents('.sidebar-list-item').remove()
      }
    })
  });
})
