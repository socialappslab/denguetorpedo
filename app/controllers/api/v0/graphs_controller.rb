# -*- encoding : utf-8 -*-
class API::V0::GraphsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/locations
  # Parameters:
  # * timeframe (required),
  # * percentages (required),
  # * neighborhood_id (optional).

  def locations
    neighborhood_id = cookies[:neighborhood_id] || params[:neighborhood_id] || @current_user.neighborhood_id
    @neighborhood = Neighborhood.find_by_id(neighborhood_id)

    # TODO: The visit_ids should be based on the actual association between locations
    # and neighborhood; not via the reports.
    @reports      = @neighborhood.reports
    @visit_ids    = @reports.joins(:location).pluck("locations.id")

    # TODO: Customize for Data Dashboard.
    # if params[:location_ids].include?("-1")
    #   # TODO: Right now, we're counting locations that are associated with a report.
    #   # Ideally, we could do something as simple as counting the locations
    #   # associated with a *neighborhood*. The problem here, however, is that
    #   # we may end up with an incongruity to Harold.
    #   @visit_ids = @neighborhood.locations.order("address ASC").pluck(:id)
    # else
    #   @visit_ids = params[:location_ids]
    # end

    timeframe   = params[:timeframe]
    percentages = params[:percentages]

    if timeframe.nil? || timeframe == "-1"
      start_time = nil
    else
      start_time = timeframe.to_i.months.ago
    end

    if percentages == "cumulative"
      @statistics = Visit.calculate_cumulative_time_series_for_locations_and_start_time(@visit_ids, start_time)
    else
      @statistics = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(@visit_ids, start_time, [])
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
