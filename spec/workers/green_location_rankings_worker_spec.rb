# -*- encoding : utf-8 -*-
require "rails_helper"

describe GreenLocationRankingsWorker do
  let(:user) 		  { create(:user) }
  let(:user2) 		{ create(:user) }
  let(:green_loc) { create(:location, :address => "N123") }
  let(:loc)       { create(:location, :address => "N456") }

  before(:each) do
    # Create a green location belonging to a user.
    [1.year.ago, 5.months.ago, 1.month.ago].each do |time|
      r = create(:negative_report, :location_id => green_loc.id, :reporter_id => user.id)
      v = create(:visit, :location_id => green_loc.id, :visited_at => time, :csv_id => 1)
      create(:inspection, :report_id => r.id, :visit_id => v.id, :identification_type => 2)
    end

    r = create(:positive_report, :location_id => loc.id, :reporter_id => user2.id)
    v = create(:visit, :location_id => loc.id, :visited_at => 1.month.ago, :csv_id => 1)
    create(:inspection, :report_id => r.id, :visit_id => v.id, :identification_type => 1)

    # We freeze the time in order to avoid a stack level too deep error.
    Sidekiq::Testing.fake!
    GreenLocationRankings.add_score_to_user(0, user)
  end

  after(:each) do
    GreenLocationRankingsWorker.jobs.clear
  end

  it "enqueues a job" do
    GreenLocationRankingsWorker.perform_async
    expect(GreenLocationRankingsWorker.jobs.count).to eq(1)
    GreenLocationRankingsWorker.jobs.clear
  end

  it "generates correct rankings" do
    GreenLocationRankingsWorker.perform_async
    GreenLocationRankingsWorker.perform_one
    expect(GreenLocationRankings.score_for_user(user)).to eq(1)
    expect(GreenLocationRankings.score_for_user(user2)).to eq(0)
  end

  describe "when scores change" do
    it "creates a post and sets correct user association on post" do
      # Run rankings again to notice the change.
      GreenLocationRankingsWorker.perform_async
      GreenLocationRankingsWorker.perform_one
      expect(Post.last.user_id).to eq(user.id)
    end

    it "doesn't create a post for user with no change/decreased score" do
      GreenLocationRankingsWorker.perform_async
      GreenLocationRankingsWorker.perform_one
      expect(Post.where(:user_id => user2.id).count).to eq(0)
    end
  end

  #----------------------------------------------------------------------------

end
