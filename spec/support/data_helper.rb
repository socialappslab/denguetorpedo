# encoding: UTF-8

#------------------------------------------------------------------------------

def populate_data
  mare = Neighborhood.find_by_name('Maré')

  10.times do |index|
    h = House.create!(:neighborhood_id => mare.id, :name => "House #{index}!")
  end

  ["a", "b", "c"].each_with_index do |letter, index|
    u = User.new(:email => "#{letter}@denguetorpedo.com")
    u.password   = "abcdefg"
    u.first_name = "#{letter}#{index}"
    u.last_name  = "Tester"
    u.house_id   = House.all.sample.id
    u.neighborhood_id = mare.id
    u.save!
  end

  u = User.find_by_email("admin@denguetorpedo.com")
  if u.nil?
    u = User.new(:email => "admin@denguetorpedo.com")
    u.password   = "abcdefg"
    u.first_name = "Admin"
    u.last_name  = "Admin"
    u.role       = "admin"
    u.neighborhood_id = mare.id
    u.save!
  end

  ["a", "b", "c"].each_with_index do |letter, index|
    u = User.find_by_email("#{letter}@denguetorpedo.com")
    Report.create!(:reporter_id => u.id, :status => Report::STATUS[:reported], :elimination_type => EliminationType.first, :report => "This is a report by #{u.display_name}", :neighborhood_id => mare.id, :completed_at => Time.now, :before_photo => File.open("./spec/support/foco_marcado.jpg"))
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

  # Populate houses and prizes.
  5.times do |index|
    h = House.create!(:neighborhood_id => mare.id, :name => "House Sponsor #{index}!", :house_type => User::Types::SPONSOR)
    u = User.create!(:email => "sponsor_#{index}@denguetorpedo.com", :house_id => h.id, :neighborhood_id => mare.id, :role => User::Types::SPONSOR, :password => "abcdefg", :first_name => "Senor", :last_name => "Sponsor ##{index}")
    Prize.create!(:user_id => u.id, :prize_name => "Prize ##{index}", :description => "This is a prize ##{index}", :cost => index * 100, :stock => index, :neighborhood_id => mare.id)
  end

  # Now, let's add prize codes which allow users to redeem prizes.
  3.times do |index|
    u = User.find_by_email("a@denguetorpedo.com")
    p = Prize.find(index + 1)
    PrizeCode.create!(:user_id => u.id, :prize_id => p.id)
  end
end

#------------------------------------------------------------------------------
