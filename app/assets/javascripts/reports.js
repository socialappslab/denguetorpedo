
// strings correspond to ids of report div
// used with function display_report_div
var report_tabs = ['all_reports_button', 'open_reports_button', 'eliminated_reports_button', 'make_report_button'];

$(document).ready(function() {

    // if error happened on create, display create tab

    if($('#error').val() == "true"){
        // update CSS to show it being selected
        selected_tab_css_update('make_report_button');

        // hide open/elimanted reports
        $('.report').each(function(){
            $(this).css('display','none');
        });
        // display new report content
        $('#new_report').css('display','block');
    }
    else{
        // style all reports as selected
        selected_tab_css_update('all_reports_button');
    }


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

});


function filter_reports(e, filter_class){

    // style tab as selected
    selected_tab_css_update(e.target.id);

    // loop through reports looking for appropriate class based on passed class (@param filter_class)
    if (filter_class === 'all'){
        $('.report').each(function(){
            $(this).css('display','block');
        });
    }
    else{
        $('.report').each(function(){
            var value = $(this).hasClass(filter_class) ? 'block' : 'none';
            $(this).css('display',value);
        })
    }
}

// pass the id of tab to change the css so that it appears as selected
// e.g. larger size, different color, etc
function selected_tab_css_update(id){

    // loop through report tabs and add active the the one that whose id is passed
    $.each(report_tabs, function(i, tab_id){
        if (tab_id == id)
            $("#" + tab_id).addClass('active');
        else {
            $("#" + tab_id).removeClass('active');
        }
    })
}
