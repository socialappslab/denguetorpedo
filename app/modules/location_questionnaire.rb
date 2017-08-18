module LocationQuestionnaire
  #----------------------------------------------------------------------------

  def self.questions_for_colombia
    return [
      {
        :code => "public_space_type",
        :body => "¿Qué tipo de espació público notifica?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "Calle"},
          {:id => 2, :body => "Colegio"},
          {:id => 3, :body => "Iglesia"},
          {:id => 4, :body => "Lote"},
          {:id => 5, :body => "Parque"},
          {:id => 6, :body => "Parqueadero"},
          {:id => 7, :body => "Negocio"},
          {:id => 8, :body => "Ladera"},
          {:id => 9, :body => "Otro"}
        ]
      }

      # {
      #   :code => "public_space_direction",
      #   :body => "¿Cuál es la dirección del espacio público?",
      #   :type => "radio",
      #   :answer_choices => [
      #     {:id => 1, :body => "CL"},
      #     {:id => 2, :body => "KR"},
      #     {:id => 3, :body => "CS"},
      #     {:id => 4, :body => "BARRIO"}
      #   ]
      # }
    ]
  end

  #----------------------------------------------------------------------------

  def self.questions_for_nicaragua
    return []
  end

  #----------------------------------------------------------------------------
end
