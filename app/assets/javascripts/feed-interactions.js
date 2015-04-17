$(document).ready(function()
{
  //---------------------------------------------------------------------------

  $(".comment-button").on("click", function(eventObj)
  {
    eventObj.preventDefault();
    parent = $(eventObj.currentTarget).parents(".thread");
    parent.children(".feed-item-new-comment").toggle()
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
        $(event.currentTarget).find('.likes_text').text(report.count.toString());
        $(event.currentTarget).data("likes_count", report.count.toString());

        likeIcon = $(event.currentTarget).find('.like-icon')
        if (report.liked == true)
          likeIcon.css("color", "#3498db")
        else
          likeIcon.css("color", "#bdc3c7")
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

  $(".feed-item-comment-form").on("submit", function(event)
  {
    // Make a copy of the new comment form.
    var currentCommentDiv = $(event.currentTarget).parents(".feed-item-new-comment");
    var newCommentHTMLdiv = currentCommentDiv.clone().wrap('<div>').parent().html();
    console.log(newCommentHTMLdiv);

    window.newDiv = newCommentHTMLdiv;

    window.currentTarget = event.currentTarget;

    $(currentCommentDiv).removeClass("feed-item-new-comment");

    window.divs = currentCommentDiv;



    event.preventDefault();
    $.ajax({
      url: event.currentTarget.action,
      data: $(event.currentTarget).serialize(),
      type: "POST",
      success : function(data){
        window.data = data;
        alert("Success!");
        currentCommentDiv.find(".feed-item-timestamp").text(data.formatted_timestamp);
        currentCommentDiv.find(".feed-item-content").text(data.content);
        currentCommentDiv.parent().append(newCommentHTMLdiv)
      },
      error: function(response) {
        window.error = response;
        console.log(response)
        if (response.responseText != "")
        {
          error = JSON.parse(response.responseText);
          alert(error.message);
        }
        else
          window.alert("Something went wrong on our end. Please try again.")
      },

      complete: function(response) {
        var button = $(event.target).find(":submit");
        button.find(".fa-refresh").hide();
        button.attr("disabled", false);
      }

    });

    return false;
  })

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
