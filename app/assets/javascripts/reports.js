$(document).ready(function() {
//	$("select.elimination_type").each(function() {
//		$(this).parent().find("select.elimination_methods").hide();
//
//		if($(this).val() == "Pratinho de planta") {
//			$(this).parent().find("select#prantinho").show();
//		} else if ($(this).val() == "Pneu") {
//			$(this).parent().find("select#pneu").show();
//		} else if ($(this).val() == "Lixo (recipientes inutilizados)") {
//			$(this).parent().find("select#lixo").show();
//		} else if ($(this).val() == "Pequenos Recipientes utilizáveis") {
//			$(this).parent().find("select#pequenos").show();
//		} else if ($(this).val() == "Grandes Recipientes Utilizáveis") {
//			$(this).parent().find("select#grandes").show();
//		} else if ($(this).val() == "Caixa d'água aberta na residência") {
//			$(this).parent().find("select#caixa").show();
//		} else if ($(this).val() == "Calha") {
//			$(this).parent().find("select#calha").show();
//		} else if ($(this).val() == "Registros abertos") {
//			$(this).parent().find("select#registros").show();
//		} else if ($(this).val() == "Laje e terraços com água") {
//			$(this).parent().find("select#laje").show();
//		} else if ($(this).val() == "Piscinas") {
//			$(this).parent().find("select#piscinas").show();
//		} else if ($(this).val() == "Poças d’água na rua") {
//			$(this).parent().find("select#pocas").show();
//		} else if ($(this).val() == "Ralos") {
//			$(this).parent().find("select#ralos").show();
//		} else if ($(this).val() == "Plantas ornamentais que acumulam água (ex: bromélias)") {
//			$(this).parent().find("select#plantas").show();
//		} else if ($(this).val() == "Outro tipo") {
//			// window.location.href = "/feedbacks/new?title=other_type";
//			$(this).find("option").filter(function() {
//				return $(this).text() == "Tipo de foco";
//			}).prop("selected", true);
//			$(this).parent().find("select#prantinho").show();
//		} else {
//			$(this).parent().find("select#prantinho").show();
//		}
//	});

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
//
//    $('.report_submission').on('click',function(e){
//        console.log("worked")   ;
//        e.preventDefault();
//    })



//      if (e.keyCode == 13){
//          $(this).next("input").focus();
//          return false;
//      }

});


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
                }
            });
        }

    }
}
