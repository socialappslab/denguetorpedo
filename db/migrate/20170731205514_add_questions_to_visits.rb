class AddQuestionsToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :questions, :json
  end
end
