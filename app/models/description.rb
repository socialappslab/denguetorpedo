class Description < ActiveRecord::Base
  attr_accessible :description, :text, :time, :updated_by

  def update_attr(description, text, time, author)



  end
end
