# encoding: utf-8

require 'spec_helper'

describe Visit do
  let!(:identified_at) { Time.now - 100.days }
  let!(:cleaned_at)    { Time.now - 3.days }
  let!(:eliminated_at) { Time.now - 3.days }
  let(:base64_image)   { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let(:photo)          { Report.base64_image_to_paperclip(base64_image) }
  let(:report)         { FactoryGirl.create(:report, :larvae => true, :before_photo => photo, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)}
  let(:location)       { FactoryGirl.create(:location, :address => "Test address")}
  let(:user)           { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  #-----------------------------------------------------------------------------

  context "When a new report comes in", :after_commit => true do
    it "creates a visit" do
      expect {
        report.save
      }.to change(Visit, :count).by(1)
    end

    it "updates an existing visit if a visit already exists" do
      report.save
      expect {
        FactoryGirl.create(:report, :larvae => true, :before_photo => photo, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)
      }.not_to change(Visit, :count)
    end

    it "sets correct visit timestamp" do
      report.save
      v = Visit.last
      expect(v.visited_at).to eq(identified_at)
    end

    it "sets visit type to identification" do
      report.save
      v = Visit.last
      expect(v.visit_type).to eq(Visit::Types::IDENTIFICATION)
    end

    describe "Calculating identification type" do
      let(:positive_report) {FactoryGirl.create(:report, :larvae => true, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)}
      let(:potential_report) {FactoryGirl.create(:report, :larvae => false, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)}
      let(:negative_report) {FactoryGirl.create(:report, :protected => false, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)}

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
        expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::NEGATIVE)
      end

      it "returns potential if no positives and at least one report is potential" do
        potential_report.save
        v = Visit.last
        expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::NEGATIVE)
      end

      it "returns negative if no positives and no potential" do
        v = Visit.new
        expect(v.calculate_identification_type_for_report(negative_report)).to eq(Report::Status::NEGATIVE)
      end
    end


  end

  #-----------------------------------------------------------------------------

  context "When an existing report comes in", :after_commit => true do
    before(:each) do
      report.save

      report.eliminated_at = eliminated_at
      report.after_photo   = photo
      report.elimination_method_id = report.breeding_site.elimination_methods.first.id
    end

    it "creates a visit" do
      expect {
        report.save
      }.to change(Visit, :count).by(1)
    end

    it "updates an existing visit if a visit already exists" do
      report.save
      expect {
        FactoryGirl.create(:report, :larvae => true, :eliminated_at => eliminated_at, :after_photo => photo, :elimination_method_id => BreedingSite.first.elimination_methods.first.id, :before_photo => photo, :report => "Saw Report #2", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => identified_at)
      }.not_to change(Visit, :count)
    end

    it "sets correct visit timestamp" do
      report.save
      v = Visit.last
      expect(v.visited_at).to eq(cleaned_at)
    end

    it "sets visit type to followup" do
      report.save
      v = Visit.last
      expect(v.visit_type).to eq(Visit::Types::FOLLOWUP)
    end
  end

  #-----------------------------------------------------------------------------
end
