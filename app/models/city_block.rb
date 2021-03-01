# -*- encoding : utf-8 -*-
class CityBlock < ActiveRecord::Base

   @logger = Rails.logger

  require 'csv'

  belongs_to :city
  belongs_to :district
  belongs_to :neighborhood

  has_many :locations

  validates_presence_of :name, :neighborhood_id, :city_id

	def self.import(file, neighborhood)
    data = IO::read(file.path).scrub("")
    table = CSV.parse(File.read(file.path), headers:true, :encoding=> 'UFT-8')
    #table = CSV.parse(data, :col_sep => ",", headers:true)
    #Estructura del poligono
    polygon_txt_ini = "{\"type\": \"FeatureCollection\",\"features\": [{\"type\": \"Feature\",\"properties\": {},\"geometry\": {\"type\": \"Polygon\",\"coordinates\": [[["
    polygon_txt_end = "]]}}]}"
    polygon_txt = ""
    #Arma el json del poligono con las coordenadas
    table.each do |row|
      #El campo coordenadas no puede quedar vacio
      if row ["coordinates"].nil?
        raise API::V0::Error.new(I18n.t("activerecord.errors.report.coordenadas"), 422) and return
      else
       text = row["coordinates"].try(:split, " ") || ""
       polygon_txt = polygon_txt + "["+text[1] + "],["+ text[0] +"],"
      end
    end
    #Elimina la ultima coma
    polygon =  (polygon_txt_ini +"" + polygon_txt+""+polygon_txt_end).sub "],]", "]]"
    #Crea el objeto con los campos requeridos en CityBlock
    object = CityBlock.new(:name => table[0]["group"], :neighborhood_id => neighborhood["id"], :district_id => neighborhood["district_id"], :city_id => neighborhood["city_id"], :polygon => polygon)
    @logger.info object
    #Insertar
    #object.save
  end

end
