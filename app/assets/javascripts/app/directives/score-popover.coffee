directive = (User) ->
  tableHTML = (points, reports_count, green_location_rankings) ->
    "<tr>
      <td class='text-center' style='width:25%; border:none;'><p>" + points + "</p><p class='light-font'>puntos</p></td>
      <td class='text-center' style='width:50%; border:none;'><p>" + reports_count + "</p><p class='light-font'>casas verdes</p></td>
      <td class='text-center' style='width:25%; border:none;'><p>" + green_location_rankings + "</p><p class='light-font'>criaderos</p></td>
    </tr>"

  templateHTML = "<div class='popover' role='tooltip'>
    <div class='arrow'></div>
    <table class='table popover-content' style='margin-bottom:0px;'><tbody></tbody></table>
  </div>"

  return {
    restrict: "A",
    link: (scope, element, attrs) ->
      element.popover({html: true, template: templateHTML, placement: "left"})
      element.hover () ->
        window.test = element
        User.get({id: attrs.userId}).$promise.then (response) ->
          popover = element.data("bs.popover");
          popover.options.content = tableHTML(response.points, response.report_count, response.green_location_ranking);
          popover.show();
      , () -> element.popover("hide")
  }

angular.module("denguechat.directives").directive("scorePopover", ["User", directive]);
