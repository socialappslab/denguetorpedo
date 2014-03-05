class EliminationMethod < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :elimination_type


  def self.create_selection
    grouped = EliminationMethod.all.group_by{|m| m.elimination_type.name}
    selection = {}
    grouped.each do |type,methods|

      selection[type] = []

      methods.each do |method|
        selection[type] << {'id'=>method.id,'name'=>method.method, 'points'=>method.points}
      end
    end

    return selection
  end
  
end
