# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < ApplicationController
  before_filter :require_login
  before_filter :update_breadcrumb
  before_filter :redirect_if_no_csv, :only => [:show, :verify]

  #----------------------------------------------------------------------------
  # GET /csv_reports

  def index
    @csvs = @current_user.csvs.order("updated_at DESC")
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
    @csv.inspections.order("position ASC").each do |ins|
      @visits_hash[ins.visit_id] ||= []
      matching_hash = @visits_hash[ins.visit_id].find {|hash| hash[:report].id == ins.report_id}
      @visits_hash[ins.visit_id] << {:report => ins.report, :inspections => []} if matching_hash.blank?
      matching_hash = @visits_hash[ins.visit_id].find {|hash| hash[:report].id == ins.report_id}
      matching_hash[:inspections] << ins
    end

    @users = @csv.location.neighborhood.users
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
    @csv = @current_user.csvs.find_by_id(params[:id])
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
