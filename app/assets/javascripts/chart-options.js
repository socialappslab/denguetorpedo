

var googleChartOptions = function(chartID, data) {
  var width = $(chartID).width();

  var colors = []

  if ( !shouldHidePositive() )
    colors.push("#e74c3c");

  if ( !shouldHidePotential() )
    colors.push("#f1c40f")

  if ( !shouldHideNegative() )
    colors.push("#2ecc71")


  var options =  {
    width: width,
    chartArea: {
      left: 50,
      right: 50,
      top: 50,
      bottom: 0,
      width: "90%",
      height: "70%"
    },
    hAxis: {},
    vAxis: {
      gridlines: {
        color: "transparent"
      },
      format: "#\'%\'"
    },
    backgroundColor: '#eff0f3',
    legend: {
      position: "none",
      alignment: "start",
      textStyle: {
        fontSize: "15"
      }
    },
    colors: colors
  };


  if ( shouldDisplayLineChart() )
    options.hAxis.showTextEvery = parseInt(data.getNumberOfRows() / 4);
  else
    options.hAxis.slantedtextangle = 90;

  return options;
}


// Checks the selected timeframe radio button and returns the appropriate
// graph.
// Scope: A helper function.
function shouldDisplayLineChart() {
  var timeline = $("#timeframe-filter input:radio:checked").map(function(index, el) { return $(el).val() });
  if (timeline[0] == "-1" || timeline[0] == "6")
    return true
  else
    return false
}

function shouldHidePositive() {
  var desiredTypes = $("input:checkbox:checked").map(function(index,el) { return $(el).attr("id") });
  if ($.inArray("chart_positive", desiredTypes) === -1)
    return true;
  else
    return false;
}

function shouldHidePotential() {
  var desiredTypes = $("input:checkbox:checked").map(function(index,el) { return $(el).attr("id") });
  if ($.inArray("chart_potential", desiredTypes) === -1)
    return true;
  else
    return false;
}

function shouldHideNegative() {
  var desiredTypes = $("input:checkbox:checked").map(function(index,el) { return $(el).attr("id") });
  if ($.inArray("chart_negative", desiredTypes) === -1)
    return true;
  else
    return false;
}

function googleDataView(data) {
  var view = new google.visualization.DataView(data);
  // Select the default display

  var columns = [0];

  if ( !shouldHidePositive() )
    columns.push(1, {calc: "stringify", sourceColumn: 1, type: "string", role: "annotation"})

  if ( !shouldHidePotential() )
    columns.push(2, {calc: "stringify", sourceColumn: 2, type: "string", role: "annotation"})

  if ( !shouldHideNegative() )
    columns.push(3, {calc: "stringify", sourceColumn: 3, type: "string", role: "annotation"})

  view.setColumns(columns);
  return view;
}


function drawChart(chartID, rawData) {
  var chartHTMLElement = document.getElementById(chartID)

  if (shouldDisplayLineChart() == true)
    chart = new google.visualization.LineChart(chartHTMLElement);
  else
    chart = new google.visualization.ColumnChart(chartHTMLElement);


  // Initialize the critical variables.

  var data      = new google.visualization.arrayToDataTable(rawData);
  var formatter = new google.visualization.NumberFormat({suffix: "%", fractionDigits: 0});
  formatter.format(data, 1);
  formatter.format(data, 2);
  formatter.format(data, 3);

  // Let's hide the columns corresponding to unchecked checkboxes.
  var view    = googleDataView(data);
  var options = googleChartOptions(chartID, data)
  chart.draw(view, options);
}
