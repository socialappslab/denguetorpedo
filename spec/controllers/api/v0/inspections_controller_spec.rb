# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::InspectionsController do
  render_views

  #--------------------------------------------------------------------------

  describe "Creating an inspection" do
    let(:location) { create(:location) }
    let(:user)     { create(:user) }
    let(:visit)    { create(:visit, :location_id => location.id, :visited_at => 7.days.ago) }

    before(:each) do
      cookies[:auth_token] = user.auth_token
      API::V0::BaseController.any_instance.stub(:authenticate_user_via_jwt).and_return(true)
      API::V0::BaseController.any_instance.stub(:current_user_via_jwt).and_return(user)
    end

    it "creates a new inspection with correct attributes" do
      post :create,  :inspection => {
        :chemically_treated => true, :larvae => true, :pupae => true, :protected => true, :breeding_site_id => true,
        :location => "Somewhere",
        :visit_id => visit.id,
        :before_photo => "data:image/png;base64,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"
      }
      r   = Report.last
      ins = Inspection.last
      expect(r.source).to eq("mobile")
      expect(r.before_photo).not_to eq(nil)
      expect(ins.source).to eq("mobile")
      expect(ins.report_id).not_to eq(nil)
    end
  end

  #--------------------------------------------------------------------------
end