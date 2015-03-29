#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < NeighborhoodsBaseController
  before_filter :require_login
  before_filter :calculate_ivars,                  :only => [:index]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
  end


  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports/new

  def new
    @csv_report = CsvReport.new
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def calculate_ivars
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")
  end

  #----------------------------------------------------------------------------

end
