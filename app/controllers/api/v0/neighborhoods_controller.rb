class API::V0::NeighborhoodsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token, :only => [:chart]

  #----------------------------------------------------------------------------
  # GET /api/v0/neighborhoods/:id/chart

  def chart
    @neighborhood = Neighborhood.find(params[:id])
    @reports      = @neighborhood.reports
    @visit_ids    = @reports.joins(:location).pluck("locations.id")

    # Use query parameters if available, but fallback to cookies if necessary.
    if params[:chart].present?
      start_time = nil
      start_time = 1.month.ago  if params[:chart][:timeframe] == "1"
      start_time = 3.months.ago if params[:chart][:timeframe] == "3"
      start_time = 6.months.ago if params[:chart][:timeframe] == "6"

      if params[:chart][:percentages] == "cumulative"
        @statistics = Visit.calculate_cumulative_time_series_for_locations_and_start_time(@visit_ids, start_time)
      else
        @statistics = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(@visit_ids, start_time, [])
      end
    elsif cookies[:chart].present?
      chart_settings = JSON.parse(cookies[:chart])

      start_time = nil
      start_time = 1.month.ago  if chart_settings["timeframe"] == "1"
      start_time = 3.months.ago if chart_settings["timeframe"] == "3"
      start_time = 6.months.ago if chart_settings["timeframe"] == "6"

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

  #----------------------------------------------------------------------------
end
