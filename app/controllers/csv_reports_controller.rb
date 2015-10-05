# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < ApplicationController
  before_filter :require_login
  before_filter :calculate_ivars, :only => [:index]
  before_filter :update_breadcrumb

  #----------------------------------------------------------------------------
  # GET /csv_reports

  def index
    @csvs = @current_user.csv_reports.order("created_at DESC")
  end

  #----------------------------------------------------------------------------
  # GET /csv_reports/new

  def new
    @neighborhood = @current_user.neighborhood
    @csv_report   = CsvReport.new
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
    @csv = @current_user.csv_reports.find(params[:id])
    @breadcrumbs << {:name => @csv.csv_file_name, :path => csv_report_path(@csv)}
  end

  #----------------------------------------------------------------------------
  # GET /csv_reports/:id/verify

  def verify
    @csv = @current_user.csv_reports.find(params[:id])
    @breadcrumbs << {:name => I18n.t("views.csv_reports.verify"), :path => verify_csv_report_path(@csv)}
  end

  #----------------------------------------------------------------------------
  # DELETE /neighborhoods/1/csv_reports/:id

  def destroy
    @csv = @current_user.csv_reports.find(params[:id])
    if @csv.destroy
      flash[:notice] = I18n.t("views.csv_reports.flashes.deleted")
      redirect_to csv_reports_path and return
    else
      render "show" and return
    end
  end

  #----------------------------------------------------------------------------

  private

  def calculate_ivars
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")
  end

  def update_breadcrumb
    @breadcrumbs << {:name => "CSV", :path => csv_reports_path}
  end

  #----------------------------------------------------------------------------

end
