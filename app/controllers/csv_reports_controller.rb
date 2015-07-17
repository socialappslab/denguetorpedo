# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < ApplicationController
  before_filter :require_login
  before_filter :calculate_ivars, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
    @csvs = @current_user.csv_reports.order("created_at DESC")
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports/new

  def new
    @neighborhood = @current_user.neighborhood
    @csv_report   = CsvReport.new
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports/:id

  def show
    @csv = @current_user.csv_reports.find(params[:id])
  end

  #----------------------------------------------------------------------------
  # DELETE /neighborhoods/1/csv_reports/:id

  def destroy
    @csv = @current_user.csv_reports.find(params[:id])
    if @csv.destroy
      flash[:notice] = "CSV was successfully deleted"
      redirect_to csv_reports_path and return
    else
      render "show" and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def calculate_ivars
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")
  end

  #----------------------------------------------------------------------------

end
