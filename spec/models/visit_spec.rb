# encoding: utf-8

require 'spec_helper'

describe Visit do
  let!(:created_at)    { Time.now - 100.days }
  let!(:eliminated_at) { Time.now - 3.days }
  let(:photo)          { Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg') }
  let(:location)       { FactoryGirl.create(:location, :address => "Test address")}
  let(:user)           { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:report)         { FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)}


  #-----------------------------------------------------------------------------

  context "when a new report is created", :after_commit => true do
    it "creates a new visit instance" do
      expect {
        FactoryGirl.create(:report, :location_id => location.id, :reporter => user)
      }.to change(Visit, :count).by(1)
    end

    it "sets the correct visit time" do
      report = FactoryGirl.create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.visited_at).to eq(created_at)
    end

    it "sets the correct visit type" do
      report = FactoryGirl.create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.visit_type).to eq(Visit::Types::INSPECTION)
    end

    it "sets the correct location" do
      report = FactoryGirl.create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.location_id).to eq(location.id)
    end

    it "sets the correct identification type on positive reports" do
      report = FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.identification_type).to eq(Report::Status::POSITIVE)
    end

    it "sets the correct identification type on potential reports" do
      report = FactoryGirl.create(:potential_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.identification_type).to eq(Report::Status::POTENTIAL)
    end

    it "sets the correct identification type on negative reports" do
      report = FactoryGirl.create(:negative_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.identification_type).to eq(Report::Status::NEGATIVE)
    end

    it "updates an existing visit if a visit already exists" do
      report.save
      expect {
        FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      }.not_to change(Visit, :count)
    end
  end

  #-----------------------------------------------------------------------------

  context "When an existing report is eliminated", :after_commit => true do
    let!(:eliminated_at) { Time.now - 3.days }
    let(:report) { FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at) }

    before(:each) do
      # This invokes after_commit callback to create a Visit instance.
      report.save

      # This eliminates the report.
      report.after_photo   				 = photo
      report.elimination_method_id = report.breeding_site.elimination_methods.first.id
      report.eliminator_id 				 = user.id
      report.eliminated_at 				 = eliminated_at
    end

    it "creates a new visit instance" do
      expect {
        report.save
      }.to change(Visit, :count).by(1)
    end

    it "sets the correct visit time" do
      report.save
      v = Visit.last
      expect(v.visited_at).to eq(eliminated_at)
    end

    it "sets the correct visit type" do
      report.save
      v = Visit.last
      expect(v.visit_type).to eq(Visit::Types::FOLLOWUP)
    end

    it "sets the correct location" do
      report.save
      v = Visit.last
      expect(v.location_id).to eq(report.location.id)
    end

    it "sets the correct identification type" do
      report.save
      v = Visit.last
      expect(v.identification_type).to eq(Report::Status::NEGATIVE)
    end

    it "updates an existing visit if a visit already exists" do
      expect {
        FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      }.not_to change(Visit, :count)
    end
  end

  #-----------------------------------------------------------------------------

  describe "Calculating identification type", :after_commit => true do
    let(:positive_report)  { FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)}
    let(:potential_report) { FactoryGirl.create(:potential_report, :location_id => location.id, :reporter => user, :created_at => created_at)}
    let(:negative_report)  { FactoryGirl.create(:negative_report, :location_id => location.id, :reporter => user, :created_at => created_at)}

    it "returns positive if report is positive" do
      v = Visit.new
      expect(v.calculate_identification_type_for_report(positive_report)).to eq(Report::Status::POSITIVE)
    end

    it "returns potential if report is potential" do
      v = Visit.new
      expect(v.calculate_identification_type_for_report(potential_report)).to eq(Report::Status::POTENTIAL)
    end

    it "returns negative if report is negative" do
      v = Visit.new
      expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::NEGATIVE)
    end

    it "returns positive if at least one report is positive" do
      positive_report.save
      v = Visit.last
      expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::POSITIVE)
    end

    it "returns potential if no positives and at least one report is potential" do
      potential_report.save
      v = Visit.last
      expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::POTENTIAL)
    end

    it "returns negative if no positives and no potential" do
      v = Visit.new
      expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::NEGATIVE)
    end
  end

  #-----------------------------------------------------------------------------

end
