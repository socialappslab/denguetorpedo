class EliminationType < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :name
  has_many :elimination_methods, dependent: :destroy
end
