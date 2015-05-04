# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8


class Dashboard::CsvReportsController < Dashboard::BaseController
  before_filter :require_login
  before_filter :calculate_ivars,                  :only => [:index]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def calculate_ivars
    @csv_reports = @current_user.csv_reports.order("created_at DESC")
  end

  #----------------------------------------------------------------------------

end
