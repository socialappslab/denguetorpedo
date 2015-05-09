# -*- encoding : utf-8 -*-
# # encoding: utf-8
# require 'action_controller'
# require "rails_helper"
#
# describe NeighborhoodsController, :type => :controller, :performance => true do
# 	render_views
#
# 	let(:user)              { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
# 	let(:n) { Neighborhood.first }
#
#
# 	before(:each) do
# 		cookies[:auth_token] = user.auth_token
#
# 		# Create users.
# 		10.times do |index|
# 			FactoryGirl.create(:user, :neighborhood_id => n.id)
# 		end
#
# 		# Create team memberships.
# 		10.times do |index|
# 			t = FactoryGirl.create(:team, :name => "Team #{index}", :neighborhood_id => n.id)
# 			u = User.all.sample
# 			FactoryGirl.create(:team_membership, :user_id => u.id, :team_id => t.id)
# 		end
#
# 		# Create posts.
# 		20.times do |index|
# 			u = User.all.sample
# 			FactoryGirl.create(:post, :user_id => u.id)
# 		end
#
# 		# Create reports.
# 		20.times do |index|
# 			u = User.all.sample
# 			FactoryGirl.create(:report, :reporter_id => u.id, :report => "Test", :before_photo => File.open(Rails.root + "spec/support/foco_marcado.jpg"), :neighborhood_id => n.id, :breeding_site_id => BreedingSite.first.id)
# 		end
# 	end
#
# 	#-----------------------------------------------------------------------------
#
# 	it "tests neighborhood page" do
# 		threads = (1..5).map do |i|
# 		  Thread.new(i) do |i|
# 				get :show, :id => n.id
# 		    puts "Running thread ##{i}"
# 		  end
# 		end
#
# 		threads.each {|t| t.join}
# 		puts "Done..."
# 	end
#
# 	#-----------------------------------------------------------------------------
# end
