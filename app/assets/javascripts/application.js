// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.all
//= require_tree .
//= require leaflet
//= require bootstrap


// TRANSITION
!function( $ ) {

  $(function () {

    "use strict"

    /* CSS TRANSITION SUPPORT (https://gist.github.com/373874)
     * ======================================================= */

    $.support.transition = (function () {
      var thisBody = document.body || document.documentElement
        , thisStyle = thisBody.style
        , support = thisStyle.transition !== undefined || thisStyle.WebkitTransition !== undefined || thisStyle.MozTransition !== undefined || thisStyle.MsTransition !== undefined || thisStyle.OTransition !== undefined

      return support && {
        end: (function () {
          var transitionEnd = "TransitionEnd"
          if ( $.browser && $.browser.webkit ) {
                transitionEnd = "webkitTransitionEnd"
          } else if ( $.browser && $.browser.mozilla ) {
                transitionEnd = "transitionend"
          } else if ( $.browser && $.browser.opera ) {
                transitionEnd = "oTransitionEnd"
          }
          return transitionEnd
        }())
      }
    })()

  })

}( window.jQuery )


//COLLAPSE

!function ($) {

  "use strict"; // jshint ;_;


 /* COLLAPSE PUBLIC CLASS DEFINITION
  * ================================ */

  var Collapse = function (element, options) {
    this.$element = $(element)
    this.options = $.extend({}, $.fn.collapse.defaults, options)

    if (this.options.parent) {
      this.$parent = $(this.options.parent)
    }

    this.options.toggle && this.toggle()
  }

  Collapse.prototype = {

    constructor: Collapse

  , dimension: function () {
      var hasWidth = this.$element.hasClass('width')
      return hasWidth ? 'width' : 'height'
    }

  , show: function () {
      var dimension
        , scroll
        , actives
        , hasData

      // TODO: Commenting this out since activating show/hide will
      // keep this.transitioning set to 1.
      // if (this.transitioning) return

      dimension = this.dimension()
      scroll = $.camelCase(['scroll', dimension].join('-'))
      actives = this.$parent && this.$parent.find('> .accordion-group > .in')

      if (actives && actives.length) {
        hasData = actives.data('collapse')
        if (hasData && hasData.transitioning) return
        actives.collapse('hide')
        hasData || actives.data('collapse', null)
      }

      this.$element[dimension](0)
      this.transition('addClass', $.Event('show'), 'shown')
      this.$element[dimension](this.$element[0][scroll])
    }

  , hide: function () {
      var dimension
      // TODO: Commenting this out since activating show/hide will
      // keep this.transitioning set to 1.
      // if (this.transitioning) return
      dimension = this.dimension()
      this.reset(this.$element[dimension]())
      this.transition('removeClass', $.Event('hide'), 'hidden')
      this.$element[dimension](0)
    }

  , reset: function (size) {
      var dimension = this.dimension()

      this.$element
        .removeClass('collapse')
        [dimension](size || 'auto')
        [0].offsetWidth

      this.$element[size !== null ? 'addClass' : 'removeClass']('collapse')

      return this
    }

  , transition: function (method, startEvent, completeEvent) {
      var that = this
        , complete = function () {
            if (startEvent.type == 'show') that.reset()
            that.transitioning = 0
            that.$element.trigger(completeEvent)
          }

      this.$element.trigger(startEvent)

      if (startEvent.isDefaultPrevented()) return

      this.transitioning = 1

      this.$element[method]('in')

      $.support.transition && this.$element.hasClass('collapse') ?
        this.$element.one($.support.transition.end, complete) :
        complete()
    }

  , toggle: function () {
      this[this.$element.hasClass('in') ? 'hide' : 'show']()
    }

  }

 /* COLLAPSIBLE PLUGIN DEFINITION
  * ============================== */

  $.fn.collapse = function (option) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('collapse')
        , options = typeof option == 'object' && option
      if (!data) $this.data('collapse', (data = new Collapse(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  $.fn.collapse.defaults = {
    toggle: true
  }

  $.fn.collapse.Constructor = Collapse


 /* COLLAPSIBLE DATA-API
  * ==================== */

  $(function () {
    $('body').on('click.collapse.data-api', '[data-toggle=collapse]', function ( e ) {
      var $this = $(this), href
        , target = $this.attr('data-target')
          || e.preventDefault()
          || (href = $this.attr('href')) && href.replace(/.*(?=#[^\s]+$)/, '') //strip for ie7
        , option = $(target).data('collapse') ? 'toggle' : $this.data()
      $(target).collapse(option)
    })
  })

}(window.jQuery);


$(document).ready(function()
{
  //---------------------------------------------------------------------------

  $(".comment-button").on("click", function(eventObj)
  {
    eventObj.preventDefault();
    parent = $(eventObj.currentTarget).parents(".feed-item")
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

    $.ajax({
      url: $(this).attr("href"),
      type: "DELETE",
      success : function(status){
        $(event.currentTarget).parents().find(".feed-item-comment").first().remove()
      }

    })
  });

  //---------------------------------------------------------------------------

})
