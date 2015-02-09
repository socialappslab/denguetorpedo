# encoding: utf-8
require 'spec_helper'

describe CsvReportsController do
  let(:user) 						{ FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:csv) 			      { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:uploaded_csv)    { ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv)) }
  let(:real_csv)        { ActionDispatch::Http::UploadedFile.new(:tempfile => File.open("spec/support/pruebaAutoreporte4.xlsx"), :filename => File.basename(csv)) }

  #-----------------------------------------------------------------------------

  context "when uploading a CSV" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "correctly sets the location address" do
      post :create, :csv_report => { :csv => uploaded_csv },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => Neighborhood.first.id

      l = Location.last
      expect(l.address).to eq("N123456")
    end

    it "creates a new CSV file" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(CsvReport, :count).by(1)
    end

    it "creates 3 new reports" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Report, :count).by(3)
    end


    describe "the parsed Report attributes" do
      before(:each) do
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      end


      it "correctly sets inspection date" do
        r = Report.order("id").first
        r.created_at.strftime("%Y-%m-%d").should eq("2014-12-24")
      end

      it "correctly sets elimination date" do
        r = Report.order("id")[1]
        r.eliminated_at.strftime("%Y-%m-%d").should eq("2014-12-26")
      end

      it "doesn't set completion date" do
        Report.find_each do |r|
          r.completed_at.should eq(nil)
        end
      end

      it "correctly sets status" do
        r = Report.order("id").first
        expect(r.status).to eq(Report::Status::POSITIVE)

        r = Report.order("id")[1]
        expect(r.status).to eq(Report::Status::POSITIVE)

        r = Report.order("id")[2]
        expect(r.status).to eq(Report::Status::POTENTIAL)
      end
    end


    describe "the parsed Visit attributes", :after_commit => true do
      before(:each) do
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      end

      it "creates 3 inspection visits" do
        expect(Visit.where(:parent_visit_id => nil).count).to eq(3)
      end

      it "creates no follow-up visits" do
        expect(Visit.where("parent_visit_id IS NOT NULL").count).to eq(0)
      end

      it "correctly sets inspection type" do
        ls = Visit.where("DATE(visited_at) = ?", "2014-12-24").first
        expect(ls.reload.identification_type).to eq(Report::Status::POSITIVE)

        # NOTE: These should be positive since the above location status is positive,
        # and still hasn't been eliminated.
        ls = Visit.where("DATE(visited_at) = ?", "2014-12-31").first
        expect(ls.identification_type).to eq(Report::Status::POTENTIAL)

        # TODO: Perhaps we should instead think of Visit as Visits that
        # essentially categorize each visit as POSITIVE, POTENTIAL, or NEGATIVE.
        # The status of a location is then dependent on whether each visit resolved
        # its status... We would need to define what "resolved" means in this context.
        ls = Visit.where("DATE(visited_at) = ?", "2015-01-10").first
        expect(ls.identification_type).to eq(Report::Status::NEGATIVE)
      end

      it "correctly sets the health report" do
        ls = Visit.where("DATE(visited_at) = ?", "2014-12-24").first
        expect(ls.health_report).to eq("3c5d")

        ls = Visit.where("DATE(visited_at) = ?", "2014-12-31").first
        expect(ls.health_report).to eq("1c1d")

        ls = Visit.where("DATE(visited_at) = ?", "2015-01-10").first
        expect(ls.health_report).to eq("0c0d")
      end
    end
  end








  context "when uploading the same CSV", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token

      post :create, :csv_report => { :csv => uploaded_csv },
      :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
      :neighborhood_id => Neighborhood.first.id
    end

    it "reuses the same location" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Location, :count)
    end

    it "does not create new CsvReport" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(CsvReport, :count)
    end

    it "does NOT create new reports" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Report, :count)
    end

    it "does NOT create new Visit" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Visit, :count)
    end

  end


  #-----------------------------------------------------------------------------

  context "when uploading a custom CSV" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "creates 4 new reports" do
      expect {
        post :create, :csv_report => { :csv => real_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Report, :count).by(4)
    end

  end

  #-----------------------------------------------------------------------------

  context "when uploading custom Nicaraguan CSV", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "returns data that matches Harold's graphs" do
      neighborhood = Neighborhood.first
      Dir[Rails.root + "spec/support/nicaragua_csv/*.xlsx"].each do |f|
        csv      = File.open(f)
        csv_file = ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

        post :create, :csv_report => { :csv => csv_file },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => neighborhood.id
      end

      reports = Report.where(:neighborhood_id => neighborhood.id)
      @visits = reports.includes(:location).map {|r| r.reload.location}.compact.uniq

      daily_stats = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(@visits)
      puts "daily_stats = #{daily_stats}"

      # cum_stats = [{:date=>"2014-01-21", :positive=>{:count=>2, :percent=>67}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2014-11-15", :positive=>{:count=>1, :percent=>33}, :potential=>{:count=>1, :percent=>33}, :negative=>{:count=>1, :percent=>33}, :total=>{:count=>3}}, {:date=>"2014-11-22", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2014-11-24", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2014-11-26", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2014-12-05", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2014-12-13", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2015-01-10", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2015-01-21", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}]
      # daily_stats = [{:date=>"2014-01-21", :positive=>{:count=>2, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>2}}, {:date=>"2014-11-15", :positive=>{:count=>1, :percent=>33}, :potential=>{:count=>1, :percent=>33}, :negative=>{:count=>1, :percent=>33}, :total=>{:count=>3}}, {:date=>"2014-11-22", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2014-11-24", :positive=>{:count=>2, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>2}}, {:date=>"2014-11-26", :positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>1}}, {:date=>"2014-12-05", :positive=>{:count=>2, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>2}}, {:date=>"2014-12-13", :positive=>{:count=>2, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>2}}, {:date=>"2015-01-10", :positive=>{:count=>3, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>3}}, {:date=>"2015-01-21", :positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}, :total=>{:count=>1}}]

      stat = daily_stats.find {|ds| ds[:date] == "2014-11-15"}
      expect(stat).to eq ({
        :date => "2014-11-15",
        :positive => {:count=>1, :percent=>33},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>1, :percent=>33},
        :total => {:count=>3}
      })


      stat = daily_stats.find {|ds| ds[:date] == "2014-11-22"}
      expect(stat).to eq ({
        :date => "2014-11-22",
        :positive => {:count=>2, :percent=>67},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>3}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-11-24"}
      expect(stat).to eq ({
        :date => "2014-11-24",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>1, :percent=>50},
        :negative => {:count=>1, :percent=>50},
        :total => {:count=>2}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-12-05"}
      expect(stat).to eq ({
        :date => "2014-12-05",
        :positive => {:count=>1, :percent=>50},
        :potential => {:count=>1, :percent=>50},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>2}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-12-13"}
      expect(stat).to eq ({
        :date => "2014-12-13",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>2, :percent=>100},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>2}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2015-01-10"}
      expect(stat).to eq ({
        :date => "2015-01-10",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>2, :percent=>67},
        :total => {:count=>3}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2015-01-21"}
      expect(stat).to eq ({
        :date => "2015-01-21",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>2, :percent=>67},
        :total => {:count=>3}
      })

    end
  end

end
