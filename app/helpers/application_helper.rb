module ApplicationHelper

  #----------------------------------------------------------------------------

  def self.temp_password_generator
    char_bank = ('0'..'9').to_a
    char_bank.shuffle.shuffle.shuffle!
    (1..8).collect{|a| char_bank[rand(char_bank.size)] }.join
  end

  #----------------------------------------------------------------------------

  def elimination_selection(selection)
    selection_list = []
    if type = EliminationType.find_by_name(selection)

      type.elimination_methods.each do |method|
          selection_list << {:name=>method.method, :points=>method.points,:id=>method.id,
                             :display=>method.method + " (" + method.points.to_s + " pontos)"}
      end

    end

    return selection_list
  end

  #----------------------------------------------------------------------------

end
