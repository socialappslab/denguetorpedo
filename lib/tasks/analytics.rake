# encoding: UTF-8

namespace :analytics do
  task :registration => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      user_count = User.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count

      data += "#{time.strftime("%Y-%m")}, #{user_count}\n"
    end

    puts data
  end

  task :posts => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      post_count = Post.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count
      user_count = User.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count
      post_per_user = (post_count.to_f / user_count).round(1)

      data += "#{time.strftime("%Y-%m")}, #{post_count}, #{post_per_user}\n"
    end

    puts data

    hash = Post.select(:user_id).group(:user_id).count.sort_by {|k,v| v}
    hash = hash[-20..-1]
    hash = hash.reverse

    data = ""
    hash.map {|user| data += "#{User.find(user[0]).name}, #{user[1]}\n" }
    puts data
  end

  task :comments => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      comm_count = Comment.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count
      user_count = User.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count
      comm_per_user = (comm_count.to_f / user_count).round(1)

      data += "#{time.strftime("%Y-%m")}, #{comm_count}, #{comm_per_user}\n"
    end

    puts data

    hash = Comment.where(:commentable_type => "Post").select(:commentable_id).group(:commentable_id).count.sort_by {|k,v| v}
    hash = hash[-20..-1]
    hash = hash.reverse

    data = ""
    hash.map {|post| data += "#{Post.find(post[0]).user.name}, #{post[1]}\n" }
    puts data
  end

  task :likes => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      like_count = Like.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count
      user_count = User.where("DATE(created_at) <= ?", time.strftime("%Y-%m-%d") ).count
      like_per_user = (like_count.to_f / user_count).round(1)

      data += "#{time.strftime("%Y-%m")}, #{like_count}, #{like_per_user}\n"
    end

    puts data

    hash = Like.where(:likeable_type => "Post").select(:likeable_id).group(:likeable_id).count.sort_by {|k,v| v}
    hash = hash[-20..-1]
    hash = hash.reverse

    data = ""
    hash.map {|user| data += "#{Post.find(user[0]).user.name}, #{user[1]}\n" }
    puts data
  end

  task :post_activity => [:environment] do
    data = ""

    within_month = []
    within_semi  = []
    within_year  = []
    User.all.to_a.each do |user|
      within_month << user if user.posts.where("DATE(created_at) >= ?", 1.month.ago.strftime("%Y-%m-%d") ).present?
      within_semi  << user if user.posts.where("DATE(created_at) >= ?", 6.months.ago.strftime("%Y-%m-%d") ).present?
      within_year  << user if user.posts.where("DATE(created_at) >= ?", 1.year.ago.strftime("%Y-%m-%d") ).present?
    end

    puts "Within month: #{within_month.count}"
    puts "Within 6 months: #{within_semi.count}"
    puts "Within a year: #{within_year.count}"


    within_month = []
    within_semi  = []
    within_year  = []
    User.all.to_a.each do |user|
      within_month << user if user.likes.where("DATE(likes.created_at) >= ?", 1.month.ago.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ?", 1.month.ago.strftime("%Y-%m-%d") ).present?
      within_semi  << user if user.likes.where("DATE(likes.created_at) >= ?", 6.months.ago.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ?", 6.months.ago.strftime("%Y-%m-%d") ).present?
      within_year  << user if user.likes.where("DATE(likes.created_at) >= ?", 1.year.ago.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ?", 1.year.ago.strftime("%Y-%m-%d") ).present?
    end

    puts "Within month: #{within_month.count}"
    puts "Within 6 months: #{within_semi.count}"
    puts "Within a year: #{within_year.count}"



    within_month = []
    within_semi  = []
    within_year  = []
    User.all.to_a.each do |user|
      within_month << user if user.posts.where("DATE(created_at) >= ?", 1.month.ago.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ?", 1.month.ago.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ?", 1.month.ago.strftime("%Y-%m-%d") ).present?
      within_semi  << user if user.posts.where("DATE(created_at) >= ?", 6.months.ago.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ?", 6.months.ago.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ?", 6.months.ago.strftime("%Y-%m-%d") ).present?
      within_year  << user if user.posts.where("DATE(created_at) >= ?", 1.year.ago.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ?", 1.year.ago.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ?", 1.year.ago.strftime("%Y-%m-%d") ).present?
    end

    puts "Within month: #{within_month.count}"
    puts "Within 6 months: #{within_semi.count}"
    puts "Within a year: #{within_year.count}"
  end

  task :retention => [:environment] do
    data = ""

    (0..36).to_a.reverse.each do |month|
      curr_month = month.months.ago
      next_month = curr_month + 1.month
      last_month = curr_month - 1.month

      active_users = 0
      User.all.to_a.each do |user|
        is_active_curr = user.csvs.where("DATE(created_at) >= ? AND DATE(created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d")).present? || user.posts.where("DATE(created_at) >= ? AND DATE(created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ? AND DATE(likes.created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ? AND DATE(comments.created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d") ).present?
        is_active_last = user.csvs.where("DATE(created_at) >= ? AND DATE(created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d")).present? || user.posts.where("DATE(created_at) >= ? AND DATE(created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ? AND DATE(likes.created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ? AND DATE(comments.created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d") ).present?

        active_users += 1 if is_active_curr && is_active_last
      end

      data += "#{curr_month.strftime("%Y-%m")}, #{active_users}\n"
    end

    puts data

    data = ""

    (0..36).to_a.reverse.each do |month|
      curr_month = month.months.ago
      next_month = curr_month + 6.months
      last_month = curr_month - 6.months

      active_users = 0
      User.all.to_a.each do |user|
        is_active_curr = user.csvs.where("DATE(created_at) >= ? AND DATE(created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d")).present? || user.posts.where("DATE(created_at) >= ? AND DATE(created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ? AND DATE(likes.created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ? AND DATE(comments.created_at) < ?", curr_month.strftime("%Y-%m-%d"), next_month.strftime("%Y-%m-%d") ).present?
        is_active_last = user.csvs.where("DATE(created_at) >= ? AND DATE(created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d")).present? || user.posts.where("DATE(created_at) >= ? AND DATE(created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d") ).present? || user.likes.where("DATE(likes.created_at) >= ? AND DATE(likes.created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d") ).present? || user.comments.where("DATE(comments.created_at) >= ? AND DATE(comments.created_at) < ?", last_month.strftime("%Y-%m-%d"), curr_month.strftime("%Y-%m-%d") ).present?

        active_users += 1 if is_active_curr && is_active_last
      end

      data += "#{curr_month.strftime("%Y-%m")}, #{active_users}\n"
    end

    puts data
  end

  task :visits => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      user_count = Visit.where("csv_id IS NOT NULL").where("DATE(visited_at) <= ?", time.strftime("%Y-%m-%d") ).count

      data += "#{time.strftime("%Y-%m")}, #{user_count}\n"
    end

    puts data
  end

  task :inspections => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      user_count = Inspection.joins(:visit).where("inspections.csv_id IS NOT NULL").where("DATE(visits.visited_at) <= ?", time).count

      data += "#{time.strftime("%Y-%m")}, #{user_count}\n"
    end

    puts data
  end

  task :indeces => [:environment] do
    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      start = time.beginning_of_month
      endin = time.end_of_month
      inspections = Inspection.includes(:report).joins(:visit).where("inspections.csv_id IS NOT NULL").where("DATE(visits.visited_at) >= ? AND DATE(visits.visited_at) <= ?", start, endin)
      puplar = inspections.find_all {|ins| ins.report.pupae == true || ins.report.larvae == true}.count
      data += "#{time.strftime("%Y-%m")}, #{puplar}\n"
    end

    puts data

    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      start = time.beginning_of_month
      endin = time.end_of_month
      visits = Visit.where("csv_id IS NOT NULL").where("DATE(visited_at) >= ? AND DATE(visited_at) <= ?", start, endin)
      locs = visits.find_all {|v| v.location_id}.uniq.count
      data += "#{time.strftime("%Y-%m")}, #{locs}\n"
    end

    puts data



    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      start = time.beginning_of_month
      endin = time.end_of_month
      ins = Inspection.joins(:visit).where("inspections.csv_id IS NOT NULL").where("DATE(visits.visited_at) >= ? AND DATE(visits.visited_at) <= ?", start, endin).count
      data += "#{time.strftime("%Y-%m")}, #{ins}\n"
    end

    puts data


    data = ""
    (0..36).to_a.reverse.each do |month|
      time = month.months.ago
      start = time.beginning_of_month
      endin = time.end_of_month
      ins = Inspection.joins(:visit).where("inspections.csv_id IS NOT NULL AND inspections.identification_type = 0").where("DATE(visits.visited_at) >= ? AND DATE(visits.visited_at) <= ?", start, endin).count
      data += "#{time.strftime("%Y-%m")}, #{ins}\n"
    end

    puts data
  end
end
