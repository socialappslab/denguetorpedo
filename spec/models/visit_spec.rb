# encoding: utf-8

require 'spec_helper'

describe Visit do

  #-----------------------------------------------------------------------------

  context "when working with several reports", :after_commit => true do
    let(:location) { FactoryGirl.create(:location, :address => "Test address")}
    let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
    let!(:identified_at) { Time.now - 100.days }
    let!(:cleaned_at)     { Time.now - 3.days }
    let(:first_report) {FactoryGirl.create(:report, :protected => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)}
    let(:second_report) {FactoryGirl.create(:report, :larvae => true, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)}

    it "resets cleaning time to nil when a positive report appears on same day" do
      first_report.save(:validate => false)

      first_report.eliminator_id = user.id
      first_report.eliminated_at = cleaned_at
      first_report.save(:validate => false)

      v = Visit.first
      expect(v.cleaned_at).to eq(cleaned_at)

      second_report.save
      expect(v.reload.cleaned_at).to eq(nil)
    end

    it "destroys the Visit if there are no more reports" do
      first_report.save(:validate => false)

      expect {
        first_report.destroy
      }.to change(Visit, :count).by(-1)
    end
  end

  #-----------------------------------------------------------------------------
end
