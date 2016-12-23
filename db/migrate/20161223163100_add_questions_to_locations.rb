class AddQuestionsToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :questions, :json
  end
end
