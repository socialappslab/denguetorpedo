class AssignPointsToPreviousAssignmentsWorker
  include Sidekiq::Worker

  def perform
    assignments = Assignment.where("date::date > ? and status LIKE 'realizado'", (Date.today - 6.months))
    reporters = []
    assignments.each do |assignment|
      assignment.users.each do |user|
        reporters << user
      end
    end
    reporters = reporters.uniq{ |r| r.id }
    reporters.each do |rep|
      rep.award_points_for_submitting
    end
  end
end
