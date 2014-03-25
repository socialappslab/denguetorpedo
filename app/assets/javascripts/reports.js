
// strings correspond to ids of report div
// used with function display_report_div
var report_divs = ['all_reports', 'open_reports', 'eliminated_reports', 'new_report'];
var default_report_div = 'all_reports';

$(document).ready(function() {

    // hide all divs but default report div
    // used to prevent children from inheriting display attribute
    for(var i = 0; i < report_divs.length; i++){
        var val = (report_divs[i] === default_report_div) ? 'block' : 'none';
        $('#' + report_divs[i]).css('display',val);
    }

    // keep the map on the page when scrolling
    $(window).scroll(function() {
        var scrollAmount = $(window).scrollTop();
        if (scrollAmount > 200) {
            $("#map_div").css("margin-top", scrollAmount - 263);
        } else {
            $("#map_div").css("margin-top", -63);
        }
    });



    // TODO @awdorsett - Are these methods still used? If so refactor
    // start of methods
	$("select.elimination_type").change(function() {
		if ($(this).val() == "Outro tipo") {
			window.location = "/feedbacks/new?title=other_type";
		}
	});
	
	$("select.elimination_methods").each(function() {
		$(this).find("option").filter(function() {
			return $(this).text() == "Método de eliminação";
		}).prop("selected", true);
	});
	$("select.elimination_methods").change(function() {
		if ($(this).val() == "Outro método") {
			window.location.href = "/feedbacks/new?title=other_method";
		} else {
			$(this).parent().find("input#selected_elimination_method").val($(this).val());
		}
	});
    // end of methods




//      if (e.keyCode == 13){
//          $(this).next("input").focus();
//          return false;
//      }

});


function display_report_div(e, id){
    e.preventDefault();

    // loop through all report div ids, hide ones not matching var id
    //   display div matching var id
    for(var i = 0; i < report_divs.length; i++){
        var val = (report_divs[i] === id) ? 'block' : 'none';
        $('#' + report_divs[i]).css('display',val);
    }
}

//@params location - json of location object for report
//@params event - click event for form submission

function update_location_coordinates(location,event){

    //make sure the form being submitted has long/lat input fields
    //i.e. don't run when selecting elimination type
    if(event.target.form[7].id == 'latitude' && event.target.form[8].id == 'longitude'){

        //if either value is null then try to get coords again
        if (location.latitude == null || location.longitude == null){
            event.preventDefault();

            //disable submit button so user cant submit multiple times
            $(".report_submission").attr("disabled",true);

                $.ajax({
                    url: "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates",
                    type: "GET",
                    timeout: 5000, // milliseconds
                    dataType: "jsonp",
                    data: {"f": "pjson", "Street": location.street_type + " " + location.street_name + " " + location.street_number},
                    success: function(m) {
                        var candidates = m.candidates;

                        //possible location found, update form values
                        if (candidates.length > 0) {
                            event.target.form[7].value = candidates[0].location.x;
                            event.target.form[8].value = candidates[0].location.y;
                        }

                       $(event.target.form).submit();

                    },
                    error: function(m) {
                        //ajax call unsuccessful, server may be down
                        // TODO @awdorsett how to handle second request for map failure
                        $(".report_submission").attr("disabled",false);
                        $(event.target.form).submit();
                    }
                });
        }

    }
}
