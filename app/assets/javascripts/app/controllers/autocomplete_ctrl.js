(function () {
  function ctrl ($scope, $attrs, $location) {
    var self = this;
    self.users         = angular.fromJson($attrs.users);
    self.querySearch   = querySearch;
    self.displayName   = displayName;
    self.selectedItemChange = selectedItemChange;
    self.selectedTextChange = selectedTextChange;
    self.selectedItem  = selectedItem();

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

    function selectedItemChange (user) {
      var path = window.location.href;
      if (user !== undefined) {
        if (path.indexOf("?") === -1)
          window.location.href = path + "?user_id=" + user.id;
        else
          window.location.href = path + "&user_id=" + user.id;
      }
    }

    function selectedTextChange (text) {
      var path = window.location.href;
      if (text == "") {
        var match = path.match(/&user_id=(.*)/g);
        if (match != null)
          window.location.href = path.replace(match[0], "")

        var match = path.match(/\?user_id=(.*)/g);
        if (match != null)
          window.location.href = path.replace(match[0], "")
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
