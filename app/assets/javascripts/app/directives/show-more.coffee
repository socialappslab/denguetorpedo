# This directive iterates over the text and hides extra text behind a Show More
# button.
# NOTE: We use $timeout here in order to ensure the proper filters run on the
# content.
directive = ($compile, $timeout) ->
  return {
    restrict: "A",
    link: (scope, element, attrs) ->
      scope.showingMore = false
      $timeout( () ->
        if element.html().length > 600
          html = "<span>" + element.html().substring(0, 600) + "</span>"
          html += '<a ng-click="showingMore=true" ng-hide="showingMore"> ... Ver más</a>';
          html += '<span ng-show="showingMore==true">' + element.html().substring(600) + '</span>'

          compiledHTML = $compile(angular.element(html))(scope)
          element.html( angular.element(compiledHTML) )
      , 300)
  }
angular.module("denguechat.directives").directive("showMore", ["$compile", "$timeout", directive]);
