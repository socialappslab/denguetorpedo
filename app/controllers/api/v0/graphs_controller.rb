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

    # Determine the timeframe based on timeframe OR custom date ranges.
    if params[:custom_start_month].present? || params[:custom_start_year].present?
      start_month = params[:custom_start_month] || "01"
      start_year  = params[:custom_start_year]  || "2010"

      start_time  = Date.parse(start_year + "-" + start_month + "-" + "01")
    end

    # if params[:custom_end_month].present? || params[:custom_end_year].present?
    #   end_month = params[:custom_end_month] || "12"
    #   end_year  = params[:custom_end_year]  || Time.zone.now.year
    #
    #   end_time  = Date.parse(end_year + "-" + end_month + "-" + Time.zone.now.day.to_s)
    # end

    # In case there were no custom start ranges, then let's rely on timeframe.
    if start_time.blank?
      if params[:timeframe].nil? || params[:timeframe] == "-1"
        start_time = nil
      else
        start_time = params[:timeframe].to_i.months.ago.strftime("%Y-%m-%d")
      end
    end


    # TODO: The visit_ids should be based on the actual association between locations
    # and neighborhood; not via the reports.
    # TODO: Right now, we're counting locations that are associated with a report.
    # Ideally, we could do something as simple as counting the locations
    # associated with a *neighborhood*. The problem here, however, is that
    # we may end up with an incongruity to Harold.
    if params[:location_ids].present?
      @visit_ids = JSON.parse(params[:location_ids])
    else
      @reports   = @neighborhood.reports
      @visit_ids = @reports.joins(:location).pluck("locations.id")
    end

    if params[:percentages] == "daily"
      @statistics = Visit.calculate_status_distribution_for_locations(@visit_ids, start_time)
    else
      @statistics = Visit.calculate_status_distribution_for_locations(@visit_ids, start_time, "monthly")
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

    # Update the cookies.
    if cookies[:chart].present?
      settings = JSON.parse(cookies[:chart])
      settings = params.slice(:timeframe, :percentages, :type, :positive, :potential, :negative)
      settings[:timeframe]   ||= "3"
      settings[:percentages] ||= "daily"
      settings[:type]        ||= "bar"
      settings[:positive]    ||= "1"
      settings[:potential]   ||= "1"
      settings[:negative]    ||= "1"

      cookies[:chart] = settings.to_json
    end

    render :json => @chart_statistics.as_json, :status => 200 and return
  end
end
