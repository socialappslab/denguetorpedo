$(document).ready(function()
{
  //---------------------------------------------------------------------------

  $(".comment-button").on("click", function(eventObj)
  {
    eventObj.preventDefault();
    parent = $(eventObj.currentTarget).parents(".feed-item-complete");
    parent.children(".feed-item-new-comment").first().toggle()
  });

  //---------------------------------------------------------------------------

  $(".show-more-content-link").on("click", function(eventObj)
  {
      eventObj.preventDefault()
      var hiddenContent = $(eventObj.currentTarget).parent().find("#hidden-post-content");
      hiddenContent.css("display", "inline")
      $(eventObj.currentTarget).hide()
  });

  //---------------------------------------------------------------------------

  $(".likes_button").click(function(event){
    event.preventDefault();

    // Trim the count of the text
    $.ajax({
      url: $(this).data("path"),
      type: "POST",
      data: {"count" : $(this).data("likes_count")},
      success : function(report){
        $(event.currentTarget).find('span').text(report.count.toString());
        $(event.currentTarget).data("likes_count", report.count.toString());

        likeIcon = $(event.currentTarget).find('span')
        if (report.liked == true)
          likeIcon.css("color", "#3498db")
        else
          likeIcon.css("color", "#8899a6")
      }
    })
  });

  //---------------------------------------------------------------------------

  $(".comment-delete-button").click(function(event){
    event.preventDefault();

    alert($(this).data("confirm"));

    $.ajax({
      url: $(this).data("path"),
      type: "DELETE",
      success : function(status){
        $(event.currentTarget).parents(".feed-item-comment").remove()
      }

    })

    return false;
  });

  //---------------------------------------------------------------------------

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
        $(event.currentTarget).parents('.sidebar-list-item').remove();
      }
    })
  });

  //---------------------------------------------------------------------------

})
