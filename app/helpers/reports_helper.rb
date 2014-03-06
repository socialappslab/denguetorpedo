module ReportsHelper
  @@prompts = {'elimination_method'=>"Selecione o método de eliminação",
                'neighborhood'=>'bairro'}
  def random_sponsors
    random_sponsors = []
    9.times do
      random_sponsors.push('home_images/sponsor'+(rand(5)+1).to_s+'.png')
    end 
    random_sponsors   
  end

  def prompt_helper type
    if @@prompts.has_key? type
      return @@prompts[type]
    end

  end
  
end