class ManualInstruction < ActiveRecord::Base
  attr_accessible :created_at, :description, :title, :updated_at, :user_id
end
