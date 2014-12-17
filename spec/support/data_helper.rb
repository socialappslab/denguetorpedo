# encoding: UTF-8

#------------------------------------------------------------------------------

def populate_data
  locations = ["San Francisco", "Managua", "Ocachicualli"]

  mare = Neighborhood.find_by_name('Maré')

  10.times do |index|
    h = Team.create!(:neighborhood_id => mare.id, :name => "Team #{index}!")
  end

  ["a", "b"].each_with_index do |letter, index|
    u = User.new(:email => "#{letter}@denguetorpedo.com")
    u.username   = "#{letter}@denguetorpedo.com"
    u.password   = "abcdefg"
    u.first_name = "#{letter}#{index}"
    u.last_name  = "Tester"
    u.neighborhood_id = mare.id
    u.save!

    TeamMembership.create(:user_id => u.id, :team_id => Team.all.sample.id)
  end

  u = User.find_by_email("c@denguetorpedo.com")
  if u.nil?
    u = User.new(:email => "c@denguetorpedo.com")
    u.username   = "c@denguetorpedo.com"
    u.password   = "abcdefg"
    u.first_name = "Coord"
    u.last_name  = "Inator"
    u.role       = User::Types::COORDINATOR
    u.neighborhood_id = mare.id
    u.save!
  end

  u = User.find_by_email("sponsor@denguetorpedo.com")
  if u.nil?
    u = User.new(:email => "sponsor@denguetorpedo.com")
    u.username   = "sponsor@denguetorpedo.com"
    u.password   = "abcdefg"
    u.first_name = "Sponsor"
    u.last_name  = "Sponsor"
    u.role       = User::Types::SPONSOR
    u.neighborhood_id = mare.id
    u.save!
  end

  u = AdminUser.find_by_email("admin@denguetorpedo.com")
  if u.nil?
    u = AdminUser.new(:email => "admin@denguetorpedo.com")
    u.password   = "abcdefgh"
    u.save!
  end

  ["a", "b", "c"].each_with_index do |letter, index|
    u = User.find_by_email("#{letter}@denguetorpedo.com")
    Report.create!(:reporter_id => u.id,
      :breeding_site_id => BreedingSite.first.id,
      :report => "This is a report by #{u.display_name}",
      :neighborhood_id => mare.id, :completed_at => Time.now,
      :before_photo => File.open("./spec/support/foco_marcado.jpg"))

    if letter == "c"
      eliminator = User.find_by_email("a@denguetorpedo.com")
      Report.create!(:reporter_id => u.id,
        :breeding_site_id => BreedingSite.first.id,
        :elimination_method_id => BreedingSite.first.elimination_methods.first.id,
        :report => "This is an eliminated report by #{u.display_name}",
        :neighborhood_id => mare.id, :completed_at => Time.now,
        :before_photo => File.open("./spec/support/foco_marcado.jpg"),
        :after_photo => File.open("./spec/support/foco_marcado.jpg"),
        :eliminator_id => eliminator.id,
        :eliminated_at => Time.now)
    end

    report = u.build_report_via_sms({ :body => "SMS report" })
    report.save!
  end

  users = User.all
  sites = BreedingSite.all
  methods = EliminationMethod.all


  reports_json = JSON.parse( JSON.load( File.open(Rails.root + "spec/support/reports.json").read ) )
  reports_json.each do |r|

    if Location.find_by_id(r["location_id"]).blank?
      r["location_id"] = Location.create!(:address => locations.sample).id
    end

    site = sites.sample

    r["neighborhood_id"] = mare.id
    r["reporter_id"]     = users.sample.id
    r["eliminator_id"]   = users.sample.id if r["eliminator_id"].present?
    r["breeding_site_id"] = site.id
    r["elimination_method_id"] = site.elimination_methods.sample.id if r["elimination_method_id"].present?
    if r["elimination_method_id"].present?
      r["eliminated_at"] = Time.now - (0..100).to_a.sample.days
    end

    report = Report.new(r)
    report.created_at = Time.now - (0..100).to_a.sample.days
    report.updated_at = report.created_at
    report.save(:validate => false)
  end


  # Populate news
  10.times do |index|
    Notice.create!(:neighborhood_id => mare.id,
      :title => "Hello Hello Hello Hello Hello Hello News ##{index}!",
      :description => "We are now live for the #{index}th time!",
      :date => Time.now + index.days,
      :location => "Mare's #{index}th block",
      :summary => "We are now live for the #{index}th time!",
      :institution_name => "Institution ##{index}")
  end

  # Populate teams and prizes.
  10.times do |index|
    h = Team.create!(:neighborhood_id => mare.id, :name => "Team Sponsor #{index}!")
    u = User.create!(:username => "sponsor_#{index}@denguetorpedo.com", :neighborhood_id => mare.id, :role => User::Types::SPONSOR, :password => "abcdefg", :first_name => "Senor", :last_name => "Sponsor ##{index}")
    TeamMembership.create(:user_id => u.id, :team_id => h.id)
    Prize.create!(:user_id => u.id, :team_id => h.id, :prize_name => "Prize ##{index}", :description => "This is a prize ##{index}", :cost => index * 100, :stock => index, :neighborhood_id => mare.id, :expire_on => Time.now + 10.years)
  end

  # Now, let's add random comments
  10.times do |index|
    c = Comment.new
    c.user_id = User.all.sample.id

    if index > 5
      c.commentable_id = Notice.all.sample.id
      c.commentable_type = Notice.name
    else
      c.commentable_id = Report.all.sample.id
      c.commentable_type = Report.name
    end

    phrases = ["Lorem ipsum dolem", "Great job!", "That could be better phrased", "YES!"]
    c.content = phrases.sample
    c.save!
  end

  # Now, let's add prize codes which allow users to redeem prizes.
  3.times do |index|
    u = User.find_by_email("a@denguetorpedo.com")
    p = Prize.find(index + 1)
    PrizeCode.create!(:user_id => u.id, :prize_id => p.id)
  end
end

#------------------------------------------------------------------------------
