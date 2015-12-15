# encoding: UTF-8

namespace :house_index_algorithm do
  task :display_db_visits => :environment do
    quinta  = Neighborhood.find(8)
    quinta_loc_ids = quinta.locations.pluck(:id)
    visits  = Visit.where("DATE(visited_at) >= '2015-07-01' AND DATE(visited_at) <= '2015-07-31'").order("visited_at ASC")
    visits  = visits.where(:location_id => quinta_loc_ids)
    loc_ids = visits.pluck(:location_id)
    inspections = Inspection.where(:visit_id => visits.pluck(:id))
    visits  = visits.map {|v| {:visited_at => v.visited_at, :location_id => v.location_id, :location => Location.find(v.location_id).address} }


    # Total visits in July: 159 (actual count from July CSV data: 479)
    # Total inspections in July: 19 (actual count from July CSV data: 215)
    # Total unique locations in July: 91 (actual count from July CSV data: 98)
    puts "Total visits in July: #{visits.count}"
    puts "Total inspections in July: #{inspections.count}"
    puts "Total unique locations in July: #{loc_ids.uniq.count}"
    puts "Locations: #{Location.where(:id => loc_ids).order("address ASC").pluck(:address)}"
    # puts JSON.pretty_generate(visits)

    # Actual locations from July CSVs
    # "N002001001", "N002001002", "N002001003", "N002001004", "N002001005", "N002001006", "N002001007", "N002001008", "N002001009", "N002001011", "N002001012", "N002001013", "N002001014", "N002001015", "N002001016", "N002001017", "N002001018", "N002001019", "N002001020", "N002001021", "N002001022", "N002001023", "N002001025", "N002001027", "N002002032", "N002002033", "N002002034", "N002002035", "N002002036", "N002002037", "N002002039", "N002002040", "N002002041", "N002002042", "N002002044", "N002002045", "N002002046", "N002002047", "N002002048", "N002002049", "N002003051", "N002003055", "N002003056", "N002003057", "N002003061", "N002003062", "N002003063", "N002003064", "N002003065", "N002003066", "N002003069", "N002003070", "N002003071", "N002003072", "N002004079", "N002004080", "N002004081", "N002004082", "N002004083", "N002004084", "N002004085", "N002004086", "N002004087", "N002004088", "N002004089", "N002004090", "N002004091", "N002004092", "N002004093", "N002004095", "N002004096", "N002004098", "N002004103", "N002004104", "N002005106", "N002005107", "N002005109", "N002005110", "N002005112", "N002005113", "N002005114", "N002005116", "N002005117", "N002005118", "N002005121", "N002006126", "N002006127", "N002006128", "N002006129", "N002006131", "N002006132", "N002006133", "N002006134", "N002006136", "N002006137", "N002006138", "N002006139", "N002006140"

    # Locations in the current DengueChat dataset (2015-12-04)
    # ["N002001001", "N002001003", "N002001005", "N002001006", "N002001007", "N002001008", "N002001009", "N002001011", "N002001012", "N002001013", "N002001014", "N002001015", "N002001016", "N002001018", "N002001019", "N002001021", "N002001022", "N002001023", "N002001025", "N002001027", "N002002032", "N002002033", "N002002034", "N002002035", "N002002036", "N002002039", "N002002040", "N002002041", "N002002042", "N002002044", "N002002045", "N002002046", "N002002047", "N002002048", "N002002049", "N002003051", "N002003055", "N002003056", "N002003057", "N002003061", "N002003062", "N002003063", "N002003064", "N002003065", "N002003066", "N002003069", "N002003070", "N002003071", "N002003072", "N002004079", "N002004080", "N002004081", "N002004082", "N002004083", "N002004084", "N002004086", "N002004087", "N002004088", "N002004089", "N002004090", "N002004091", "N002004092", "N002004093", "N002004095", "N002004096", "N002004098", "N002004103", "N002004104", "N002005106", "N002005107", "N002005109", "N002005110", "N002005112", "N002005113", "N002005116", "N002005117", "N002005118", "N002005121", "N002006126", "N002006127", "N002006128", "N002006129", "N002006131", "N002006132", "N002006133", "N002006134", "N002006136", "N002006137", "N002006138", "N002006139", "N002006140"]

    # Locations in July CSVs that are not in current DengueChat dataset
    # ["N002001002", "N002001004", "N002001017", "N002001020", "N002002037", "N002004085", "N002005114"]

    # After uploading the CSVs for these locations, the new total visits is
    # Total visits: 168 visits
    # Total unique locations in July: 98 (MATCH!)
  end
end
