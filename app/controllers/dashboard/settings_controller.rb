# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
    @city = current_user.city
  end
  def volunteers
    neighborhoods = City.find(params[:city_id]).neighborhoods
    @volunteers = []
    neighborhoods.each do |n|
      n.users.each do |u|
        volunteer = {}
        volunteer[:id] = u.id
        if u.first_name.blank? && u.last_name.blank?
          volunteer[:name] = u.name
        else
          volunteer[:name] = "#{u.first_name} #{u.last_name}"
        end
        volunteer[:picture] = u.picture
        @volunteers << volunteer
      end
    end
    @volunteers = @volunteers.uniq{ |v|v[:id]}.sort_by{|v|v[:id]}
    render json: @volunteers.to_json, status: 200
  end

  #----------------------------------------------------------------------------

end
#----------------------------------------------------------------------------

