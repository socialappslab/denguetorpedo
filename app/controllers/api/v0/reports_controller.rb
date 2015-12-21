# -*- encoding : utf-8 -*-
class API::V0::ReportsController < API::V0::BaseController
  skip_before_action :authenticate_user_via_device_token, :only => [:destroy, :update]
  before_action :current_user, :only => [:update, :destroy]

  #----------------------------------------------------------------------------
  # GET /api/v0/reports

  def index
    render :json => {:reports => @user.reports.order("created_at DESC").as_json(
      :only => [:id, :report, :created_at],
      :methods => [:formatted_created_at],
      :include => {:location => {:only => [:address]}, :breeding_site => {:only => [:id, :description_in_es, :description_in_pt]}})}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/reports/:id

  def update
    @report                           = Report.find_by_id(params[:id])
    @report.save_without_before_photo = true
    @report.save_without_after_photo  = true

    if @report.update_attributes(params[:report])
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@report.errors.full_messages[0], 403)
    end
  end

  #----------------------------------------------------------------------------
  # POST /api/v0/reports

  def create
    paperclip_image = nil
    if params[:report][:before_photo]
      base64_image = params[:report][:before_photo]
      params[:report].except!(:before_photo)
      filename             = @user.display_name.underscore + "_report.jpg"
      paperclip_image      = prepare_base64_image_for_paperclip(base64_image, filename)
    end

    @report                 = Report.new(params[:report])
    @report.reporter_id     = @user.id
    @report.neighborhood_id = @user.neighborhood_id
    @report.completed_at    = Time.zone.now
    @report.before_photo    = paperclip_image

    if params[:report][:address].present?
      location = Location.find_or_create_by(:address => params[:report][:address], :neighborhood_id => @report.neighborhood_id)
      @report.location_id = location.id
    end

    if @report.save
      # Let's associate a visit and inspection.
      visit = Visit.find_or_create_visit_for_location_id_and_date(@report.location_id, @report.created_at)
      Inspection.create(:visit_id => visit.id, :report_id => @report.id, :identification_type => @report.original_status)

      render :json => @report.as_json(:only => [:id, :report],
      :methods => [:formatted_created_at],
      :include => {
        :location => {:only => [:address]},
        :breeding_site => {
          :only => [:id, :description_in_es, :description_in_pt]
        }
      }), :status => 200 and return
    else
      raise API::V0::Error.new(@report.errors.full_messages[0], 403)
    end
  end

  #----------------------------------------------------------------------------
  # DELETE /api/v0/reports/:id

  def destroy
    @report = @current_user.reports.find_by_id(params[:id])
    @report.destroy
    render :json => {:redirect_path => neighborhood_reports_path(@report.neighborhood)}, :status => 200 and return
  end

end
