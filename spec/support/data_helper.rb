# encoding: UTF-8

#------------------------------------------------------------------------------

def populate_users
  ["a", "b", "c"].each_with_index do |letter, index|
    u = User.create!(:email => "#{letter}@denguetorpedo.com")
    u.password = "abcdefg"
    u.first_name = "#{letter}#{index}"
    u.last_name  = "Tester"
    u.save!
  end

  u = User.find_by_email("admin@denguetorpedo.com")
  if u.nil?
    u = User.new(:email => "admin@denguetorpedo.com")
    u.password   = "abcdefg"
    u.first_name = "Admin"
    u.last_name  = "Admin"
    u.role       = "admin"
    u.save!
  end
end

#------------------------------------------------------------------------------

def populate_notices_houses_sponsors_and_prizes
  mare = Neighborhood.find_by_name('Maré')

  10.times do |index|
    Notice.create!(:neighborhood_id => mare.id, :title => "Hello News ##{index}!", :description => "We are now live for the #{index}th time!")
  end

  5.times do |index|
    House.create!(:neighborhood_id => mare.id, :name => "House #{index}!")
  end


  5.times do |index|
    h = House.create!(:neighborhood_id => mare.id, :name => "House Sponsor #{index}!", :house_type => User::Types::SPONSOR)
    u = User.create!(:email => "sponsor_#{index}@denguetorpedo.com", :house_id => h.id, :neighborhood_id => mare.id, :role => User::Types::SPONSOR, :password => "abcdefg", :first_name => "Senor", :last_name => "Sponsor ##{index}")
    Prize.create!(:user_id => u.id, :prize_name => "Prize ##{index}", :description => "This is a prize ##{index}", :cost => index * 100, :stock => index, :neighborhood_id => mare.id)
  end
end

#------------------------------------------------------------------------------
