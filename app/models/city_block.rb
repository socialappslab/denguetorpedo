# -*- encoding : utf-8 -*-
class CityBlock < ActiveRecord::Base

   @logger = Rails.logger

  require 'csv'

  belongs_to :city
  belongs_to :district
  belongs_to :neighborhood

  has_many :locations

  validates_presence_of :name, :neighborhood_id, :city_id

	def self.import(file)
    data = IO::read(file.path).scrub("")
    table = CSV.parse(File.read(file.path), headers:true, :encoding=> 'UFT-8')
    #table = CSV.parse(data, :col_sep => ",", headers:true)
    #Estructura del poligono
    polygon_txt_ini = "{\"type\": \"FeatureCollection\",\"features\": [{\"type\": \"Feature\",\"properties\": {},\"geometry\": {\"type\": \"Polygon\",\"coordinates\": [["
    polygon_txt_end = "]] }}]}"
    polygon_txt = ""
    guardar = false
    nro_manzana = 0
    neighborhood_params = ""
    index = 0
    city_blank = false
    #Arma el json del poligono con las coordenadas
    table.each do |row|
      index = index +1

      if guardar
        #Elimina la ultima coma
        polygon =  (polygon_txt_ini +"" + polygon_txt+""+polygon_txt_end).sub "],]", "]]"
        #Crea el objeto con los campos requeridos en CityBlock
        object = CityBlock.new(:name => nro_manzana.to_s, :neighborhood_id => neighborhood_params[0]["id"], :district_id => neighborhood_params[0]["district_id"], :city_id => neighborhood_params[0]["city_id"], :polygon => polygon)
        @logger.info object
        object.save
        guardar = false
      end

      if row["data-locations-number"] == "1"
        polygon_txt = ""
        city_blank = false
        #buscamos que la comunidad sea correcta
        neighborhood_params = Neighborhood.where(:name => row["data-locations-Comunidad"])
        if neighborhood_params.blank?
          raise API::V0::Error.new(I18n.t("activerecord.errors.report.neighborhood")+": "+row["data-locations-Comunidad"], 422) and return
        end
        city_block_params = CityBlock.where(:name  => row["data-locations-group"], :neighborhood_id => neighborhood_params[0]["id"], :city_id => neighborhood_params[0]["city_id"])
        p city_block_params
        if city_block_params.blank?
          city_blank = true
          #Si no existe entonces seguimos
          nro_manzana = row["data-locations-group"]
          #El campo coordenadas no puede quedar vacio
          if row ["data-locations-coordinates"].nil?
            raise API::V0::Error.new(I18n.t("activerecord.errors.report.coordenadas"), 422) and return
          else
           text = row["data-locations-coordinates"].try(:split, ",") || ""
           polygon_txt = polygon_txt + "["+text[1] + ","+ text[0] +"],"
          end
        end
      else
        if city_blank
          if row["data-locations-coordinates"].nil?
            raise API::V0::Error.new(I18n.t("activerecord.errors.report.coordenadas"), 422) and return
          else
             text = row["data-locations-coordinates"].try(:split, ",") || ""
             polygon_txt = polygon_txt + "["+text[1] + ","+ text[0] +"],"
          end
        end
      end

      if index < table.length
        if table[index]["data-locations-number"] == "1" && city_blank
          guardar = true
        end
      else index == table.length && !guardar
        if city_blank
          guardar = true
        end
      end

    end

    if guardar
      #Elimina la ultima coma
      polygon =  (polygon_txt_ini +"" + polygon_txt+""+polygon_txt_end).sub "],]", "]]"
      #Crea el objeto con los campos requeridos en CityBlock
      object = CityBlock.new(:name => nro_manzana, :neighborhood_id => neighborhood_params[0]["id"], :district_id => neighborhood_params[0]["district_id"], :city_id => neighborhood_params[0]["city_id"], :polygon => polygon)
      @logger.info object
      #Insertar
      object.save
    end
  end

end
