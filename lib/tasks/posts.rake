# encoding: UTF-8

namespace :posts do

  task :add_neighborhood => :environment do
    Post.find_each do |post|
      post.update_column(:neighborhood_id, post.user.neighborhood_id)
    end
  end

end
