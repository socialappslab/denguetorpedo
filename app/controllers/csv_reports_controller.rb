# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < ApplicationController
  before_filter :require_login
  before_filter :update_breadcrumb
  before_filter :redirect_if_no_csv, :only => [:show, :verify]
  before_action :calculate_header_variables

  #----------------------------------------------------------------------------
  # GET /csv_reports

  def index
    if @current_user.coordinator?
      @csvs  = Spreadsheet.order("updated_at ASC")
      @csvs  = @csvs.where(:user_id => params[:user_id]) if params[:user_id].present?
      @users = User.order("username ASC")

      if params[:neighborhood_id].present?
        loc_ids = Location.where(:neighborhood_id => params[:neighborhood_id]).pluck(:id)
        @csvs = @csvs.where(:location_id => loc_ids)
      end
    elsif @current_user.delegator?
      @csvs  = Spreadsheet.order("updated_at ASC")
      @csvs  = @csvs.where(:user_id => params[:user_id]) if params[:user_id].present?
      @users = @current_user.neighborhood.users
    else
      @csvs = @current_user.csvs
    end

    if params[:sort] == "date"
      @csvs = @csvs.reorder("updated_at ASC") if params[:order]  == "asc"
      @csvs = @csvs.reorder("updated_at DESC") if params[:order] == "desc"
    end

    if params[:sort] == "user"
      #ids = User.reorder("username ASC").pluck(:id)  if params[:order] == "asc"
      #ids = User.reorder("username DESC").pluck(:id) if params[:order] == "desc"
      #@csvs = @csvs.sort {|csv1, csv2| ids.index(csv1.user_id) <=> ids.index(csv2.user_id)}
      @csvs = @csvs.joins(:user).reorder("users.username #{params[:order]}")
    end

    if params[:sort] == "location"
      #ids = Location.reorder("address ASC").pluck(:id)  if params[:order] == "asc"
      #ids = Location.reorder("address DESC").pluck(:id) if params[:order] == "desc"
      #@csvs = @csvs.sort {|csv1, csv2| ids.index(csv1.location_id) <=> ids.index(csv2.location_id)}
      @csvs = @csvs.joins(:location).reorder("locations.address #{params[:order]}")
    end

    @pagination_count = @csvs.count
    @pagination_limit = 20
    offset = (params[:page].to_i || 0) * @pagination_limit
    @csvs = @csvs.limit(@pagination_limit).offset(offset)
  end

  #----------------------------------------------------------------------------
  # GET /csv_reports/new

  def new
    @neighborhood = @current_user.neighborhood
    @csv_report   = Spreadsheet.new
    @breadcrumbs << {:name => I18n.t("views.buttons.upload_csv"), :path => new_csv_report_path}
  end

  #----------------------------------------------------------------------------
  # GET /csv_reports/batch

  def batch
    @neighborhood = @current_user.neighborhood
    @breadcrumbs << {:name => I18n.t("views.csv_reports.batch_upload"), :path => batch_csv_reports_path}
  end

  #----------------------------------------------------------------------------
  # GET /csv_reports/:id

  def show
    @visits_hash = {}
    @csv.visits.each do |visit|
      @visits_hash[visit.id] ||= []

      visit.inspections.order("position ASC").each do |ins|
        matching_hash = @visits_hash[visit.id].find {|hash| hash[:report].id == ins.report_id}
        @visits_hash[visit.id] << {:report => ins.report, :inspections => []} if matching_hash.blank?
        matching_hash = @visits_hash[visit.id].find {|hash| hash[:report].id == ins.report_id}
        matching_hash[:inspections] << ins unless matching_hash[:inspections].include?(ins)
      end
    end

    if @current_user.coordinator?
      @users = User.order("username ASC")
    else
      @users = @csv.location.neighborhood.users
    end
    @breadcrumbs << {:name => @csv.csv_file_name, :path => csv_report_path(@csv)}
  end

  #----------------------------------------------------------------------------
  # GET /csv_reports/:id/verify

  def verify
    @breadcrumbs << {:name => I18n.t("views.csv_reports.verify"), :path => csv_report_path(@csv)}
  end

  #----------------------------------------------------------------------------
  # DELETE /neighborhoods/1/csv_reports/:id

  def destroy
    @csv = @current_user.csvs.find(params[:id])
    if @csv.destroy
      flash[:notice] = I18n.t("views.csv_reports.flashes.deleted")
      redirect_to csv_reports_path and return
    else
      render "show" and return
    end
  end

  #----------------------------------------------------------------------------

  private

  def redirect_if_no_csv
    if @current_user.coordinator?
      @csv = Spreadsheet.find_by_id(params[:id])
    else
      @csv = @current_user.csvs.find_by_id(params[:id])
    end
    if @csv.blank?
      flash[:alert] = "Usted no tiene este CSV!"
      redirect_to csv_reports_path and return
    end
  end

  def update_breadcrumb
    @breadcrumbs << {:name => "CSV", :path => csv_reports_path}
  end

  #----------------------------------------------------------------------------

end
