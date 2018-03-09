module VisitQuestionnaire
  #----------------------------------------------------------------------------

  def self.questions_for_colombia
    return [
      {
        :code => "presence_near_person_with_symptoms",
        :body => "¿Estoy en la casa de la persona con sintomas?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "full_name_with_symptoms",
        :body => "¿Cuál es el nombre y el apellido completo de la persona con sintomas?",
        :type => "text"
      },
      {
        :code => "date_of_birth",
        :body => "¿Cuál es la fecha de nacimiento de la persona con sintomas?",
        :type => "date"
      },
      {
        :code => "gender",
        :body => "¿La persona con sintomas es mujer o hombre?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "Mujer"},
          {:id => 2, :body => "Hombre"}
        ]
      },
      {
        :code => "identification_document_type",
        :body => "¿Cuál es el tipo de documento de indentificación de la persona con síntomas?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "Cedula de Ciudadania"},
          {:id => 2, :body => "Registro Civil"},
          {:id => 3, :body => "Tarjeta de Identidad"},
          {:id => 4, :body => "Pasaporte"},
          {:id => 5, :body => "Cedula de Extranjeria"},
          {:id => 6, :body => "No contestar a esta pregunta"}
        ]
      },
      {
        :code => "identification_document_number",
        :body => "¿Cuál es el número del documento de identificación de la persona con síntomas?",
        :type => "text"
      },
      {
        :code => "telephone_number",
        :body => "¿Cuál es el número del teléfono celular o fijo de la persona con síntomas?",
        :type => "text"
      },
      {
        :code => "symptoms",
        :body => "Seleccionan los sintomas de la persona:",
        :type => "checkbox",
        :answer_choices => [
          {:id => 1, :body => "Fiebre"},
          {:id => 2, :body => "Mal-estar"},
          {:id => 3, :body => "Dolor muscular"},
          {:id => 4, :body => "Dolor articular"},
          {:id => 5, :body => "Dolor abdominal"},
          {:id => 6, :body => "Brote de color rojo en el cuerpo"},
          {:id => 7, :body => "Conjuntivitis"},
          {:id => 8, :body => "Dolor de cabeza"},
          {:id => 9, :body => "Otro" }
        ]
      },
      {
        :code => "date_of_beginning_of_symptoms",
        :body => "¿Cuál es la fecha de inicio de los síntomas?",
        :type => "date"
      }
    ]
  end

  def self.questions_for_paraguay
    return [
      {
        :code => "presence_near_person_with_symptoms",
        :body => "¿Estoy en la casa de la persona con sintomas?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "full_name_with_symptoms",
        :body => "¿Cuál es el nombre y el apellido completo de la persona con sintomas?",
        :type => "text"
      },
      {
        :code => "date_of_birth",
        :body => "¿Cuál es la fecha de nacimiento de la persona con sintomas?",
        :type => "date"
      },
      {
        :code => "gender",
        :body => "¿La persona con sintomas es mujer o hombre?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "Mujer"},
          {:id => 2, :body => "Hombre"}
        ]
      },
      {
        :code => "identification_document_type",
        :body => "¿Cuál es el tipo de documento de indentificación de la persona con síntomas?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "Cedula de Ciudadania"},
          {:id => 2, :body => "Registro Civil"},
          {:id => 3, :body => "Tarjeta de Identidad"},
          {:id => 4, :body => "Pasaporte"},
          {:id => 5, :body => "Cedula de Extranjeria"},
          {:id => 6, :body => "No contestar a esta pregunta"}
        ]
      },
      {
        :code => "identification_document_number",
        :body => "¿Cuál es el número del documento de identificación de la persona con síntomas?",
        :type => "text"
      },
      {
        :code => "telephone_number",
        :body => "¿Cuál es el número del teléfono celular o fijo de la persona con síntomas?",
        :type => "text"
      },
      {
        :code => "symptoms",
        :body => "Seleccionan los sintomas de la persona:",
        :type => "checkbox",
        :answer_choices => [
          {:id => 1, :body => "Fiebre"},
          {:id => 2, :body => "Mal-estar"},
          {:id => 3, :body => "Dolor muscular"},
          {:id => 4, :body => "Dolor articular"},
          {:id => 5, :body => "Dolor abdominal"},
          {:id => 6, :body => "Brote de color rojo en el cuerpo"},
          {:id => 7, :body => "Conjuntivitis"},
          {:id => 8, :body => "Dolor de cabeza"},
          {:id => 9, :body => "Otro" }
        ]
      },
      {
        :code => "date_of_beginning_of_symptoms",
        :body => "¿Cuál es la fecha de inicio de los síntomas?",
        :type => "date"
      }
    ]
  end

  #----------------------------------------------------------------------------

  def self.questions_for_nicaragua
    return [
      {
        :code => "pregnant",
        :body => "Hay alguien embarazada?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "pregnant_months",
        :body => "Cuantos meses de embarazo lleva?",
        :type => "text",
        :parent => {code: "pregnant", display: [2]}
      },
      {
        :code => "child_born_with_zika",
        :body => "Ha nacido un niño/a enfermo/a por Zika u otro problema?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "child_born_with_zika_explain",
        :body => "Explique",
        :type => "text",
        :parent => {code: "child_born_with_zika", display: [2]}
      },
      {
        :code => "child_born_with_zika_when",
        :body => "Cuando?",
        :type => "date",
        :parent => {code: "child_born_with_zika", display: [2]}
      },
      {
        :code => "dcz_rash",
        :body => "Se ha enfermado alguien con rash o fiebre?",
        :type => "radio",
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "dcz_rash_dengue",
        :body => "Con Dengue",
        :type => "radio",
        :parent => {code: "dcz_rash", display: [2]},
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "dcz_rash_dengue_when",
        :body => "Cuando?",
        :type => "date",
        :parent => {code: "dcz_rash_dengue", display: [2]}
      },
      {
        :code => "dcz_rash_zika",
        :body => "Con Zika",
        :type => "radio",
        :parent => {code: "dcz_rash", display: [2]},
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "dcz_rash_zika_when",
        :body => "Cuando?",
        :type => "date",
        :parent => {code: "dcz_rash_zika", display: [2]}
      },
      {
        :code => "dcz_rash_chika",
        :body => "Con Chikungunya",
        :type => "radio",
        :parent => {code: "dcz_rash", display: [2]},
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      },
      {
        :code => "dcz_rash_chika_when",
        :body => "Cuando?",
        :type => "date",
        :parent => {code: "dcz_rash_chika", display: [2]}
      },
      {
        :code => "minsa_referral",
        :type => "radio",
        :body => "Se ha referido al MINSA para diagnostico?",
        :answer_choices => [
          {:id => 1, :body => "No"},
          {:id => 2, :body => "Si"}
        ]
      }
    ]
  end

  #----------------------------------------------------------------------------

end
