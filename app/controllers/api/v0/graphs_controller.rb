# -*- encoding : utf-8 -*-
include GreenLocationSeries

require "csv"

class API::V0::GraphsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/timeseries

  def timeseries
    if params[:custom_start_month].present? || params[:custom_start_year].present?
      start_month = params[:custom_start_month] || "01"
      start_year  = params[:custom_start_year]  || "2010"
      start_time  = Time.zone.parse("#{start_year}-#{start_month}-01")
    end

    if params[:custom_end_month].present? || params[:custom_end_year].present?
      end_month = params[:custom_end_month] || "12"
      end_year  = params[:custom_end_year]  || Time.zone.now.year
      end_days  = Time.days_in_month(end_month.to_i)
      end_time  = Time.zone.parse("#{end_year}-#{end_month}-#{end_days}")
    end

    # In case there were no custom start ranges, then let's rely on timeframe.
    if start_time.blank?
      if params[:timeframe].nil? || params[:timeframe] == "-1"
        start_time = nil
      else
        start_time = params[:timeframe].to_i.months.ago
      end
    end

    # NOTE: We're sending a geographies object that encapsulates the 'category' type
    # we should search against.
    nids        = params[:neighborhoods] && JSON.parse(params[:neighborhoods])
    geographies = params[:geographies] && JSON.parse(params[:geographies])
    if nids.blank? && geographies.blank?
      raise API::V0::Error.new("Debe seleccionar al menos un comunidad", 422) and return
    end

    if nids.present?
      neighborhoods = Neighborhood.where(:id => nids).includes(:locations)
      location_ids  = neighborhoods.map {|n| n.locations.pluck(:id)}.flatten.uniq
    else
      location_ids = []

      nids          = geographies.find_all {|g| g["code"] == "neighborhood" }.map {|g| g["id"]}
      neighborhoods = Neighborhood.where(:id => nids).includes(:locations)
      location_ids += neighborhoods.map {|n| n.locations.pluck(:id)}.flatten.uniq

      cids   = geographies.find_all {|g| g["code"] == "city" }.map {|g| g["id"]}
      cities = City.where(:id => cids)
      location_ids += cities.map {|item| item.locations.pluck(:id)}.flatten.uniq

      dids = geographies.find_all {|g| g["code"] == "district" }.map {|g| g["id"]}
      districts = District.where(:id => dids)
      location_ids += districts.map {|item| item.locations.pluck(:id)}.flatten.uniq

      location_ids.uniq!
    end

    # set end_time to the date of the last inspection
    if !end_time.blank?
      end_time = Visit.where(location_id: location_ids).maximum(:visited_at)
    end

    # unit is either daily or monthly
    @statistics = Visit.calculate_time_series_for_locations(location_ids, start_time, end_time, params[:unit])
    @statistics.each do |shash|
      [:positive, :potential, :chemically_treated, :protected, :negative, :total].each do |status|
        locations = Location.where(:id => shash[status][:locations]).order("address ASC")
        shash[status][:locations] = locations.pluck(:address)
        shash[status][:coordinates]  = locations.map {|loc| {:latitude => loc.latitude, :longitude => loc.longitude}}
      end
    end

    @odds_ratios = Visit.calculate_odds_ratio_for_locations(location_ids, start_time, end_time, params[:unit])

    respond_to do |format|
      format.csv do
        filename = neighborhoods.map {|n| n.name.gsub(" ", "_").downcase}.join("_") + "_visita_datos.csv"
        send_data generate_csv_for_timeseries(@statistics), :filename => filename
      end

      format.json do
        Time.use_zone("America/Guatemala") do
          render "api/v0/graph/timeseries" and return
        end
      end
    end
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/locations
  # Parameters:
  # * timeframe (required),
  # * percentages (required),
  # * neighborhood_id (optional).
  # def locations
  #   neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])
  #   start_time   = 8.months.ago.beginning_of_month
  #   end_time     = Time.zone.now.end_of_month
  #   location_ids = neighborhood.locations.pluck(:id)
  #
  #   Time.use_zone("America/Guatemala") do
  #     statistics = Visit.calculate_time_series_for_locations(location_ids, start_time, end_time, params[:unit])
  #     @statistics = statistics
  #     render "api/v0/graph/timeseries" and return
  #   end
  # end

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/green_locations

  def green_locations
    city = City.find(params[:city])
    location_ids = city.locations.pluck(:id)

    #end_time   = Time.zone.now.end_of_week
    end_time = Visit.where(location_id: location_ids).maximum(:visited_at)
    start_time = end_time - 6.months
    @series = GreenLocationSeries.time_series_for_city(city, start_time, end_time)

    # We will pad empty data with green locations = 0.
    while start_time < end_time
      if @series.find {|s| s[:date].strftime("%Y%W") == start_time.end_of_week.strftime("%Y%W")}.blank?
        @series << {:date => start_time.end_of_week, :green_houses => nil}
      end

      start_time += 1.week
    end

    @series.sort_by! {|s| s[:date]}

    render "api/v0/graph/green_locations"
  end



  private

  def generate_csv_for_timeseries(timeseries)
    CSV.generate do |csv|
      csv << [
        "Fecha de visita",
        "Lugares positivos (%)",
        "Lugares potenciales (%)",
        "Lugares sin criaderos (%)",
        "Total lugares",
        "% positivos",
        "% potenciales",
        "% sin criaderos",
        "Lugares positivos",
        "Lugares potenciales",
        "Lugares sin criaderos",
        "Lugares"
      ]
      timeseries.each do |series|
        csv << [
          series[:date],
          series[:positive][:count],
          series[:potential][:count],
          series[:negative][:count],
          series[:total][:count],
          series[:positive][:percent],
          series[:potential][:percent],
          series[:negative][:percent],
          series[:positive][:locations].join(","),
          series[:potential][:locations].join(","),
          series[:negative][:locations].join(","),
          series[:total][:locations].join(",")
        ]
      end
    end

  end

end
