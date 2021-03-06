var fileUploadDirective = function() {
  return {
    restrict: 'A',
    link: function (scope, element, attr) {
      element.bind('change', function (event) {
        window.compression.compressFileFromHTMLInput(event.target);
      });
    }
  }
}


// TODO: Refactor this into its own directive.
window.compression = {}
window.compression.compressFileFromHTMLInput = function(element) {
  window.test = element;
  var canvas     = $(element).parent().find("canvas")[0];
  var preview    = $(element).parent().find(".preview");
  var file       = element.files[0];
  var compressedHTMLInput = $(element).parent().find(".compressed_photo")

  if (!file.type.match('image.*'))
    return;

  var reader = new FileReader();
  reader.onload = (function(file) {
    return function(e) {
      var image = new Image();
      image.src = e.target.result;

      image.onload = function () {
        var compressedImage = compressImageOntoCanvas(image, canvas)
        $(preview).attr({src: compressedImage, title: escape(file.name)});
        $(element).val("");
        $(compressedHTMLInput).val(compressedImage)
      };
    };
  })(file);

  reader.readAsDataURL(file);
}



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


angular.module("denguechat.directives").directive("fileUpload", fileUploadDirective);
