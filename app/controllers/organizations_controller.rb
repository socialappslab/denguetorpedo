# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class OrganizationsController < ApplicationController
  before_filter :require_login, except: [:city_blocks, :volunteers, :assignment]
  before_filter :identify_org, except: [:city_blocks, :volunteers, :assignment]
  before_filter :identify_selected_membership, except: [:city_blocks, :volunteers, :assignment]
  before_filter :update_breadcrumbs, except: [:city_blocks, :volunteers, :assignment]
  after_filter :verify_authorized, except: [:city_blocks, :volunteers, :assignment]
  before_action :calculate_header_variables, except: [:city_blocks, :volunteers, :assignment]


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
  end

  def assignment
    @barrio = params[:id_barrio]
    @assignment = Assignment.find(params[:id])
    render json: @assignment.to_json(include: :city_block, include: :users), status: 200
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

  def prueba
    @barrio = params[:id_barrio]
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
