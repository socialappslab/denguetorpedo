# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class OrganizationsController < ApplicationController
  before_filter :require_login, except: [:city_blocks, :volunteers, :assignments_post]
  before_filter :identify_org, except: [:city_blocks, :volunteers, :assignments_post]
  before_filter :identify_selected_membership, except: [:city_blocks, :volunteers, :assignments_post]
  before_filter :update_breadcrumbs, except: [:city_blocks, :volunteers, :assignments_post]
  after_filter :verify_authorized, except: [:city_blocks, :volunteers, :assignments_post]
  before_action :calculate_header_variables, except: [:city_blocks, :volunteers, :assignments_post]


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
    @future_assignments = Assignment.where('date > ?', DateTime.now).order(date: 'desc').limit(3)
  end

  def assignments_post
    
  end

  def city_blocks
    blocks = City.find(params[:city_id]).city_blocks
    @city_blocks = []
    blocks.each do |b|
      block = {}
      block[:id] = b.id
      block[:block_name] = b.name
      @city_blocks << block
    end
    render json: @city_blocks.to_json, status: 200
  end

  def volunteers
    users = User.all
    @volunteers = []
    users.each do |u|
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
    render json: @volunteers.to_json, status: 200
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
end
