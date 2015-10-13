# -*- encoding : utf-8 -*-
require "rails_helper"

describe CsvParsingWorker do
  let(:user) 		  { create(:user) }
  let(:user2) 		  { create(:user) }
  let(:green_loc) { create(:location, :address => "N123") }
  let(:loc)       { create(:location, :address => "N456") }

  before(:each) do
    Sidekiq::Testing.fake!

    # Create a green location belonging to a user.
    [1.year.ago, 5.months.ago, 1.month.ago].each do |time|
      r = create(:negative_report, :location_id => green_loc.id, :reporter_id => user.id)
      v = create(:visit, :location_id => green_loc.id, :visited_at => time)
      create(:inspection, :report_id => r.id, :visit_id => v.id, :identification_type => 2)
    end

    r = create(:positive_report, :location_id => loc.id, :reporter_id => user2.id)
    v = create(:visit, :location_id => loc.id, :visited_at => 1.month.ago)
    create(:inspection, :report_id => r.id, :visit_id => v.id, :identification_type => 1)

    skip "TODO: Sidekiq drain causes stack level too deep..."
  end

  it "generates correct rankings" do
    GreenLocationRankingsWorker.perform_async
    GreenLocationRankingsWorker.drain
    expect(GreenLocationRankings.score_for_user(user)).to eq(1)
    expect(GreenLocationRankings.score_for_user(user2)).to eq(0)
  end

  describe "when scores change" do
    it "creates a post for user with increased score" do

    end

    it "doesn't create a post for user with no change/decreased score" do
    end
  end

  #----------------------------------------------------------------------------

end
