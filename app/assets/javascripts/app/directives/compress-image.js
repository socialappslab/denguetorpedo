
var compressFileFromHTMLInput = function(element) {
  var file = element.files[0];

  element = angular.element(element);
  element.parent().append("<canvas style='display: none;'></canvas>");
  preview = element.parent().find(".preview")
  var canvas     = element.parent().find("canvas")[0];
  var compressedHTMLInput = element.parent().find(".compressed_photo")

  if (!file.type.match('image.*'))
    return;

  var reader = new FileReader();
  reader.onload = (function(file) {
    return function(e) {
      var image = new Image();
      image.src = e.target.result;
      image.onload = function () {
        var compressedImage = compressImageOntoCanvas(image, canvas)
        preview.attr({src: compressedImage, title: escape(file.name)});
        element.val("");
        $(compressedHTMLInput).val(compressedImage)
      };
    };
  })(file);

  reader.readAsDataURL(file);
}



// Helper function.
compressImageOntoCanvas = function(image, canvas) {
  var width  = image.width;
  var height = image.height;
  var maxWidth  = 517;
  var maxHeight = 600;

  if (width > height) {
    if (width > maxWidth) {
      height *= maxWidth / width;
      width = maxWidth;
    }
  }
  else {
    if (height > maxHeight) {
      width *= maxHeight / height;
      height = maxHeight;
    }
  }

  // Draw the canvas image with new dimensions, and append.
  canvas.height = height;
  canvas.width  = width;
  var ctx = canvas.getContext("2d");
  ctx.drawImage(image, 0, 0, width, height);

  // NOTE: We're using 0.75 JPEG quality per this article:
  // http://www.html5rocks.com/en/tutorials/speed/img-compression/
  return canvas.toDataURL("image/jpeg", 1.0);
}



var directive = function(){
  return {
    restrict: "A",
    link: function(scope, element, attrs) {
      element.on("change", function(event) {
        if ( window.File && window.FileReader && window.FileList && window.Blob )
          compressFileFromHTMLInput(event.target);
        else
        {
          alert('The File APIs are not fully supported in this browser.');
          return false;
        }
      })
    }
  }
}

angular.module("denguechat.directives").directive("compressImage", directive);
