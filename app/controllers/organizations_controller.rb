# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class OrganizationsController < ApplicationController
  before_filter :require_login, except: [:city_blocks, :volunteers, :assignment, :ultimos_recorridos_list, :menos_recorridos_list, :city_select, :city_select_map]
  before_filter :identify_org, except: [:city_blocks, :volunteers, :assignment, :ultimos_recorridos_list, :menos_recorridos_list, :city_select, :city_select_map]
  before_filter :identify_selected_membership, except: [:city_blocks, :volunteers, :assignment, :ultimos_recorridos_list, :menos_recorridos_list, :city_select, :city_select_map]
  before_filter :update_breadcrumbs, except: [:city_blocks, :volunteers, :assignment, :ultimos_recorridos_list, :menos_recorridos_list, :city_select, :city_select_map]
  after_filter :verify_authorized, except: [:city_blocks, :volunteers, :assignment, :ultimos_recorridos_list, :menos_recorridos_list, :city_select, :city_select_map, :cityblockinfo, :locationinfo, :mapcityblock, :cityblockassigns, :neighborhoodlocation]
  before_action :calculate_header_variables, except: [:city_blocks, :volunteers, :assignment, :ultimos_recorridos_list, :menos_recorridos_list, :city_select, :city_select_map]
  
  #----------------------------------------------------------------------------
  # GET /settings

  def settings
    @organization = current_user.selected_membership.organization
    authorize @organization
  end

  #----------------------------------------------------------------------------
  # GET /settings/users

  def users
    authorize @organization

    @memberships = @organization.memberships.includes(:user).order("user_id")
    @breadcrumbs = nil
  end

  #----------------------------------------------------------------------------
  # GET /settings/teams

  def teams

    @teams = @organization.teams.order("id ASC")
    authorize @organization
  end


  #----------------------------------------------------------------------------
  # GET /settings/assignments

  def assignments
    authorize @organization
    @city = current_user.city
    @city_blocks = @city.city_blocks.order(name: "asc")
    @future_assignments = Assignment.where('date >= ?', DateTime.now.beginning_of_day).order(date: 'desc')
    @ciudades = City.find(@city.id).neighborhoods
    @barrios = City.find(@city.id).last_visited_city_blocks_barrios(@ciudades.first.id, @city.id)
    @barrios_menos = City.find(@city.id).less_visited_city_blocks_barrios(@ciudades.first.id, @city.id)
    @parameter = Parameter.where("key = ?", "organization.citymap.#{@city.id}")

    @map_url = @parameter.length > 0 ? @parameter[0].value : ""

    @assignments = Assignment.all
  end
  
  #----------------------------------------------------------------------------
  # GET /settings/territorio

  def territorio
    @organization = current_user.selected_membership.organization
    authorize @organization
    @city = current_user.city
    @city_blocks = @city.city_blocks.order(name: "asc")
    @future_assignments = Assignment.where('date >= ?', DateTime.now.beginning_of_day).order(date: 'desc')
    @ciudades = City.find(@city.id).neighborhoods
    @barrios = City.find(@city.id).last_visited_city_blocks_barrios(@ciudades.first.id, @city.id)
    @barrios_menos = City.find(@city.id).less_visited_city_blocks_barrios(@ciudades.first.id, @city.id)
    @parameter = Parameter.where("key = ?", "organization.citymap.#{@city.id}")
    @map_url = @parameter.length > 0 ? @parameter[0].value : ""

  end

  def city_select
    if params[:id_city].to_i === 0
      render json: nil, status:200
    else
      @ciudades = City.find(params[:id_city]).neighborhoods
      render json: @ciudades.to_json, status:200
    end
  end

  def city_select_map
    if params[:id_city].to_i === 0
      render json: nil, status:200
    else
      @mapurls = City.where(id:params[:id_city]).take #Parameter.where("key = ?", "organization.citymap.#{params[:id_city]}")
      render json: @mapurls, status:200
    end
  end

  def ultimos_recorridos_list
    if params[:id_barrio].to_i === 0
      @barrios = City.find(params[:city_id]).last_visited_city_blocks
    else  
      @barrios = City.find(params[:city_id]).last_visited_city_blocks_barrios(params[:id_barrio], params[:city_id])
    end
    render json: @barrios.to_json, status:200
  end

  def menos_recorridos_list
    if params[:id_barrio].to_i === 0
      @barrios_menos = City.find(params[:city_id]).less_visited_city_blocks
    else
      @barrios_menos = City.find(params[:city_id]).less_visited_city_blocks_barrios(params[:id_barrio], params[:city_id])
    end
    render json: @barrios_menos.to_json, status:200
  end

  def assignment
    @assignment = Assignment.find(params[:id])
    render json: @assignment.to_json(:city_block, include: :users), status: 200
  end

  def assignments_post
    authorize @organization
    city_block = CityBlock.find(params[:block].to_i)
    users = User.where(id: params[:volunteers].split(',').map{|v|v.to_i})
    if !params[:assignment_id].blank?
      @assignment = Assignment.find(params[:assignment_id])
    else
      @assignment = Assignment.new()
    end
    @assignment.task = params[:task]
    @assignment.notes = params[:notes]
    @assignment.status = params[:status]
    logger.info(current_user.neighborhood.city.time_zone)
    set_time_zone do
      @assignment.date = DateTime.parse("#{params[:date]} #{Time.zone.formatted_offset}")
    end
    @assignment.city_block = city_block
    @assignment.users = users
    if @assignment.status == 'pendiente' && @assignment.date.beginning_of_day < DateTime.now.beginning_of_day
      flash[:error] = "No se puede agregar un recorrido como pendiente en una fecha anterior a la actual"
      @city = current_user.city
      @city_blocks = @city.city_blocks.order(name: "asc")
      @future_assignments = Assignment.where('date >= ?', DateTime.now.beginning_of_day).order(date: 'desc')
      render :assignments
    else
      if @assignment.save
        flash[:notice] = "Asignación guardada con éxito"
        redirect_to :assignments_organizations
      else
        flash[:error] = "Ocurrió un error al guardar. Favor intentar de nuevo"
        @city = current_user.city
        @city_blocks = @city.city_blocks.order(name: "asc")
        @future_assignments = Assignment.where('date >= ?', DateTime.now.beginning_of_day).order(date: 'desc')
        render :assignments
      end
    end
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

  def cityblockinfo
    cityblock =  CityBlock.where(name:params[:city_id]).take
    barrio = cityblock.neighborhood_id.to_s
    id=cityblock.id.to_s
    locations = cityblock.locations
    cantidadcasas = Location.find_by_sql("select * from 
      locations 
      where neighborhood_id = "+barrio+" and city_block_id = "+id+";")

    c= 0;
    d = 0;
    record = {}
    max_inspection = 0
    last_visit = DateTime.new(1991, 07, 11, 20, 10, 0)
    locations.each do |l|
      visit =  Visit.where(location:l).order("visited_at DESC").first
      if visit and visit.visited_at > last_visit
        last_visit = visit.visited_at
      end
      c = c +Inspection.where(location:l).count()
    end
    locations.each do |l|
      d = d + Visit.where(location:l).count()
    end

    record[:obj] =  cityblock
    record[:count_locations] = cantidadcasas.count()
    record[:count_inspection] = c
    record[:count_visit] = d
    record[:last_visit_date] = last_visit
    render json: record.to_json, status: 200
  end

  def locationinfo
    locations = Location.where(city_id:9)
    render json: locations.to_json, status:200
  end


  def mapcityblock 


    @cityblocks_set =CityBlock.find_by_sql("select city_blocks.id,
    city_blocks.polygon,
    city_blocks.name,
    count(distinct visits.visited_at),
    MAX(visited_at) as max_group,
    (select MAX(visited_at) from visits inner join locations on( locations.id= visits.location_id)
     where locations.neighborhood_id="+params[:neighborhood_id]+") as max	
  
  from city_blocks 
  
  left outer join 
    locations on( locations.city_block_id= city_blocks.id) 
  left outer join visits on(visits.location_id= locations.id)
  where city_blocks.neighborhood_id="+params[:neighborhood_id]+"
  GROUP BY city_block_id,city_blocks.name,city_blocks.polygon,city_blocks.id;")


    #@cityblocks_set  = []
    #max_inspection = 0
    # calculate  the max number of inspection in the set, for the max
    #cityblocks.each do |cb|  
    #  c = 0
    #  cb.locations.each do |l|
    #    c = c + Inspection.where(location:l).count()
    #  end   
    #  if max_inspection < c 
    #    max_inspection =  c 
    #  end
    #end
    
    #cityblocks.each do |cb|
      #block = {}
      #c = 0    

      #cb.locations.each do |l|
      #  c = c + Inspection.where(location:l).count()
      #end

      #block[:block]= cb
      #block[:polygon] = cb.polygon
      #block[:inspection_quantity] = c 
      #block[:max_inspection] =  max_inspection
      #@cityblocks_set << block
    #end
    
    render json: @cityblocks_set.to_json, status:200
  end



  def neighborhoodlocation
    neighborhood = Neighborhood.where(id:params[:neighborhood_id]).take
    render json: neighborhood.to_json, status:200
  end

  def cityblockassigns 
    assignments =  Assignment.where(city_block_id:params[:city_block_id])
    render json: assignments.to_json(:include=>:users), status:200
  end

  #----------------------------------------------------------------------------
  # PUT /organizations/:id

  def update
    @org = @selected_membership.organization
    authorize(@org)
    @org.name = params[:organization][:name]
    if @org.save
      redirect_to settings_path and return
    else
      render settings_path and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def identify_org
    @organization = current_user.selected_membership.organization
  end

  def update_breadcrumbs
    @breadcrumbs = nil
  end

  def set_time_zone(&block)
    if current_user
      Time.use_zone(TZInfo::Timezone.get(current_user.neighborhood.city.time_zone), &block)
    else
      Time.use_zone("America/Guatemala", &block)
    end
  end
end
