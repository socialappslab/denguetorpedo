module HouseQuiz
  def self.questions
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
        :type => "number",
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
        :type => "number",
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
        :type => "number",
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
        :type => "number",
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
end
