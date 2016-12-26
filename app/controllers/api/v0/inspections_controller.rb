# -*- encoding : utf-8 -*-
class API::V0::InspectionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_action :authenticate_user_via_jwt, :only => [:create]
  before_action :current_user_via_jwt,      :only => [:create]

  #----------------------------------------------------------------------------
  # POST /api/v0/inspections

  def create
    visit = Visit.find_by_id(params[:inspection][:visit_id])

    # Let's create an associated report.
    r = Report.new(params[:inspection].slice(:chemically_treated, :larvae, :pupae, :protected, :breeding_site_id, :before_photo))
    r.report          = params[:inspection][:location]
    r.reporter_id     = @current_user.id
    r.location_id     = visit.location_id
    r.neighborhood_id = @current_user.neighborhood_id

    # puts "r: #{r.breeding_site_id}"
    unless r.save
      raise API::V0::Error.new(r.errors.full_messages[0], 403)
    end

    # At this point, a report exists. Let's create the associated Inspection.

    @inspection          = Inspection.new
    @inspection.report   = r
    @inspection.identification_type = r.original_status
    @inspection.position = visit.inspections.count + 1
    @inspection.visit    = visit
    if @inspection.save
      render :json => {}, :status => 200 and return
    else
      raise API::V0::Error.new(@inspection.errors.full_messages[0], 403)
    end
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/inspections/:id

  def update
    @inspection = Inspection.find_by_id(params[:id])
    if @inspection.update_attributes(params[:inspection])
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@inspection.errors.full_messages[0], 403)
    end
  end
end
