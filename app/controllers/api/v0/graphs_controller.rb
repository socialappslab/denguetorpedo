# -*- encoding : utf-8 -*-
class API::V0::GraphsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/locations?location_ids=

  def locations
    # TODO
    neighborhood_id = cookies[:neighborhood_id] || @current_user.neighborhood_id
    @neighborhood   = Neighborhood.find_by_id(neighborhood_id)

    if params[:location_ids].include?("-1")
      # TODO: Right now, we're counting locations that are associated with a report.
      # Ideally, we could do something as simple as counting the locations
      # associated with a *neighborhood*. The problem here, however, is that
      # we may end up with an incongruity to Harold.
      @visit_ids = @neighborhood.locations.order("address ASC").pluck(:id)
    else
      @visit_ids = params[:location_ids]
    end

    # Extract the chart settings from the cookies.
    chart_settings = JSON.parse(cookies[:chart])

    start_time = nil
    start_time = 1.month.ago  if chart_settings["timeframe"] == "1"
    start_time = 3.months.ago if chart_settings["timeframe"] == "3"
    start_time = 6.months.ago if chart_settings["timeframe"] == "6"

    if chart_settings["percentages"] == "cumulative"
      @statistics = Visit.calculate_cumulative_time_series_for_locations_and_start_time(@visit_ids, start_time)
    else
      @statistics = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(@visit_ids, start_time)
    end

    # Format the data in a way that Google Charts can use.
    @chart_statistics = [[I18n.t('views.statistics.chart.time'), I18n.t('views.statistics.chart.percent_of_positive_sites'), I18n.t('views.statistics.chart.percent_of_potential_sites'), I18n.t('views.statistics.chart.percent_of_negative_sites')]]
    @statistics.each do |hash|
      @chart_statistics << [
        hash[:date],
        hash[:positive][:percent],
        hash[:potential][:percent],
        hash[:negative][:percent]
      ]
    end

    render :json => @chart_statistics.as_json, :status => 200 and return
  end
end
