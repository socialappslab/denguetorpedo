(function () {
  function ctrl ($scope, $attrs, $location) {
    var self = this;
    self.users         = angular.fromJson($attrs.users);
    self.querySearch   = querySearch;
    self.displayName   = displayName;
    self.selectedItem  = selectedItem();
    $scope.loadingPage = false;

    // ******************************
    // Internal methods
    // ******************************

    /**
     * Search for states... use $timeout to simulate
     * remote dataservice call.
     */
    function querySearch (query) {
      var results = query ? self.users.filter( createFilterFor(query) ) : self.users;
      return results;
    }

    function displayName (user) {
      if (!user)
        return ""
      return user.username + " (" + user.name + ")";
    }

    function selectedItem () {
      var id = extractUserId();
      if (id) {
        return self.users.filter(function(el) { return el.id == id})[0]
      }
    }

    function extractUserId () {
      var match = window.location.href.match(/user_id=(\d*)/i);
      if (match) {
        return match[1];
      } else {
        return null
      }
    }

    $scope.loadUserCSV = function() {
      if (self.selectedItem) {
        window.location.href =  window.location.pathname + "?user_id=" + self.selectedItem.id;
      } else {
        var match = window.location.href.match(/(\?|\&)user_id=(.*)/g);
        if (match != null)
          window.location.href = window.location.href.replace(match[0], "")
      }
    }

    /**
     * Create filter function for a query string
     */
    function createFilterFor(query) {
      var lowercaseQuery = angular.lowercase(query);
      return function filterFn(state) {
        return (state.username.indexOf(lowercaseQuery) === 0 || state.name.indexOf(lowercaseQuery) === 0);
      };

    }
  }

  angular.module("denguechat.controllers").controller("autocompleteCtrl", ["$scope", "$attrs", "$location", ctrl]);
})();
