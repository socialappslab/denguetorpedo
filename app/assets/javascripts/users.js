$(document).ready(function()
{
  $(".comment-button").on("click", function(eventObj)
  {
    eventObj.preventDefault();

    parent = $(eventObj.currentTarget).parents(".feed-item")
    parent.children(".feed-item-comments").show()
  })
})
