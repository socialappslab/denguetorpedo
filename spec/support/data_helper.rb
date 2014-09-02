# encoding: UTF-8

#------------------------------------------------------------------------------

def populate_data
  mare = Neighborhood.find_by_name('Maré')

  10.times do |index|
    h = Team.create!(:neighborhood_id => mare.id, :name => "Team #{index}!")
  end

  ["a", "b"].each_with_index do |letter, index|
    u = User.new(:email => "#{letter}@denguetorpedo.com")
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
    Report.create!(:reporter_id => u.id, :breeding_site_id => BreedingSite.first.id, :report => "This is a report by #{u.display_name}", :neighborhood_id => mare.id, :completed_at => Time.now, :before_photo => File.open("./spec/support/foco_marcado.jpg"))
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
    u = User.create!(:email => "sponsor_#{index}@denguetorpedo.com", :neighborhood_id => mare.id, :role => User::Types::SPONSOR, :password => "abcdefg", :first_name => "Senor", :last_name => "Sponsor ##{index}")
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
