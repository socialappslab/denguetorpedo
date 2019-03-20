require "sidekiq"
require 'json'
require 'nokogiri'

class OdkSpreadsheetParsingWorker 
  include Sidekiq::Worker
  sidekiq_options :queue => :odk_parsing, :retry => true, :backtrace => true
  
  def self.perform 
    locations = nil
    inspectionsPerVisit = nil

    #se obtienen organizaciones agrupadas por sus parametros
    organizations = Parameter.all.group_by do |parameter| 
      parameter.organization_id
    end
    organizations.each do |id, parameters|
      organizations[id] = parameters.group_by { |parameter| parameter.key }
    end


    #empieza el parser para todas las organizaciones, en este caso solo se recorre la organizacion TopaDengue.PY
    organizations.each do |organizationId, parameters| 
      # si la organizacion iterada cuenta con los parametros requeridos por el parser
      if(!parameters["organization.data.visits.url"].nil? && !parameters["organization.data.locations.url"].nil? && !parameters["organization.data.inspections.url"].nil?) 
        # agregar else if para mas organizaciones
        if(Organization.find(organizationId).name == "TopaDengue.PY")
          #se obtiene el documento xml de preguntas
          xmldoc = parameters["organization.data.xml-form"] != nil ? Nokogiri::HTML(open(parameters["organization.data.xml-form"][0].value)) : nil
          #se obtiene el usuario 
          defaultUser =  parameters["organization.sync.default-user"] != nil ? parameters["organization.sync.default-user"][0].value : nil
          
          #se obtienen los locations
          locationsHeader = []
          open(parameters["organization.data.locations.url"][0].value) do |locationsFile|
            tempLocationFile = locationsFile.read
            locationsHeader = tempLocationFile.split($/)[0].split(",")
            locations = tempLocationFile.split($/)[1..-1].group_by do |line| 
              line.split(",")[21].split("\r")[0]
            end
          end 

          #se obtienen las inspecciones agrupadas por visitas
          inspectionsHeader = []
          open(parameters["organization.data.inspections.url"][0].value) do |inspectionsFile|
            tempInspectionsFile = inspectionsFile.read
            inspectionsHeader = tempInspectionsFile.split($/)[0].split(",")
            inspectionsPerVisit = tempInspectionsFile.split($/)[1..-1].group_by do |line| 
              line.split(",")[15]
            end
          end

          visitsDuplicateArrayController = []
          #se obtienen las visitas
          open(parameters["organization.data.visits.url"][0].value) do |visitsFile|
            file = visitsFile.read
            visitsHeader = file.split($/)[0].split(",")
            file.split($/)[1..-1].each_with_index do |visit,visitsIndex| 
              visitArray = visit.split(",")
              visitId = visitArray[visitsHeader.index("KEY")]
              locationId = visitArray[visitsHeader.index("PARENT_KEY\r")].strip

              #filtro de visitas duplicadas
              if !visitsDuplicateArrayController.include? visitId
                visitsDuplicateArrayController.push(visitId)
                #si el id de la visita no esta cargado en la planilla, se descarta la misma
                #si no existen inspecciones para la visita iterada y si no existe el location, se descarta la misma
                if((!inspectionsPerVisit[visitId].eql? nil) && (inspectionsPerVisit[visitId].length > 0) && (!locations[locationId].eql? nil) ) 
                  fileName = locations[locationId][0].split(',')[locationsHeader.index("data-location-final")].strip != "" ?  locations[locationId][0].split(',')[locationsHeader.index("data-location-final")][0..7] : locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code")].strip != "" ? locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code")][0..7] : locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code_manual")][0..7]

                  if(fileName.length === 8)
                    
                    workbook = RubyXL::Workbook.new
                    worksheet = workbook[0]
                    header = ["Fecha de visita (YYYY-MM-DD)" ,"Auto-reporte dengue/chik",	"Tipo de criadero",	"Localización", "¿Protegido?", "¿Abatizado?", "¿Larvas?", "¿Pupas?", "¿Foto de criadero?", "Fecha de eliminación (YYYY-MM-DD)",	"¿Foto de eliminación?", "Comentarios sobre tipo y/o eliminación"]
                    header.each_with_index  do |string, index| 
                      worksheet.add_cell(3, index, string) 
                    end
          

                    visitDate =  visitArray[visitsHeader.index("data-visit_group-visit_date")].insert(6,'20')
                    visitStatus =  visitArray[visitsHeader.index("data-visit_group-location_status")]
                    visitHostGender =  visitArray[visitsHeader.index("data-visit_group-visit_form-visit-visit_host_gender")]
                    visitHostAge =  visitArray[visitsHeader.index("data-visit_group-visit_form-visit-visit_host_age")]
                    visitServicesLarvicide =   visitArray[visitsHeader.index("data-visit_group-visit_form-services_larvicide")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-services_larvicide")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-services_larvicide")]
                    visitServicesFumigation =   visitArray[visitsHeader.index("data-visit_group-visit_form-services_fumigation")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-services_fumigation")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-services_fumigation")]
                    visitObs =  visitArray[visitsHeader.index("data-visit_group-visit_form-visit_obs")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-visit_obs")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-visit_obs")]
                    visitAutoreporte =  visitArray[visitsHeader.index("data-visit_group-visit_form-autoreporte")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-autoreporte")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-autoreporte")]
                    visitAutoreporteNumberDengue =  visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-auto_report_numbers-auto_report_number_dengue")]
                    visitAutoreporteNumberChik =  visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-auto_report_numbers-auto_report_number_chik")]
                    visitAutoreporteNumberZika =  visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_reporte_number_zika")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_reporte_number_zika")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-auto_report_numbers-auto_reporte_number_zika")]
                    visitAutoreporteZikaNumberPregnant =  visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-auto_report_numbers-auto_report_zika_number_pregnant")]
                    visitAutoreporteSymptoms = visitArray[visitsHeader.index("data-visit_group-visit_form-symptoms")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-symptoms")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-symptoms")]
                    visitAutoreporteSymptomsGender = visitArray[visitsHeader.index("data-visit_group-visit_form-symptoms_report-symptoms_gender")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-symptoms_report-symptoms_gender")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-symptoms_report-symptoms_gender")]
                    visitAutoreporteSymptomsList = visitArray[visitsHeader.index("data-visit_group-visit_form-symptoms_report-symptom_list")].strip != "" ? visitArray[visitsHeader.index("data-visit_group-visit_form-symptoms_report-symptom_list")] : visitArray[visitsHeader.index("data-visit_group-visit_form-visit-symptoms_report-symptom_list")]
                    questions = []             
        
                    inspectionsDuplicateArrayController = []
                    inspectionsPerVisit[visitId].each_with_index do |inspection,inspectionIndex|
                      tempInspection = inspection.split(",")
                    
                      #filtro de inspecciones duplicadas
                      if !inspectionsDuplicateArrayController.include? tempInspection[inspectionsHeader.index("KEY\r")]
                        inspectionsDuplicateArrayController.push(inspectionsHeader.index("KEY\r"))
                        worksheet.add_cell(4+inspectionIndex, 0, visitDate) 
                        worksheet.add_cell(4+inspectionIndex, 2, tempInspection[inspectionsHeader.index("data-visit_group-inspection-breeding_site_code")]) #tipo de criadero data-visit_group-inspection-breeding_site_code
                        worksheet.add_cell(4+inspectionIndex, 4, tempInspection[inspectionsHeader.index("data-visit_group-inspection-br_protected")]) #protegido? data-visit_group-inspection-br_protected
                        worksheet.add_cell(4+inspectionIndex, 6, tempInspection[inspectionsHeader.index("data-visit_group-inspection-br_larvae")]) #larvas? data-visit_group-inspection-br_larvae
                        worksheet.add_cell(4+inspectionIndex, 7, tempInspection[inspectionsHeader.index("data-visit_group-inspection-br_pupae")]) #pupas? data-visit_group-inspection-br_pupae
                        worksheet.add_cell(4+inspectionIndex, 9, tempInspection[inspectionsHeader.index("data-visit_group-inspection-br_elimination_date")]) #fecha de eliminacion data-visit_group-inspection-br_elimination_date
                      
                        #por cada inspeccion, se genera un campo denominado questions con formato jsonb, en el mismo se almacenan las preguntas extraidas desde el documento xml y las respuestas correspondientes, siempre que el mismo exista
                        if(xmldoc != nil)
                          questions.push({:code => "data-visit_group-location_status", :body => xmldoc.xpath('//*[@id="/data/visit_group/location_status:label"]')[0].text.strip, :answer => visitStatus})
                          questions.push({:code => "data-visit_group-visit_form-visit-visit_host_gender", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit/visit_host_gender:label"]')[0].text.strip, :answer => visitHostGender})
                          questions.push({:code => "data-visit_group-visit_form-visit-visit_host_age", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit/visit_host_age:label"]')[0].text.strip, :answer => visitHostAge})
                          questions.push({:code => "data-visit_group-visit_form-services_fumigation", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/services_fumigation:label"]')[0].text.strip, :answer => visitServicesFumigation})
                          questions.push({:code => "data-visit_group-visit_form-services_larvicide", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/services_larvicide:label"]')[0].text.strip, :answer => visitServicesLarvicide})
                          questions.push({:code => "data-visit_group-visit_form-visit_obs", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit_obs:label"]')[0].text.strip, :answer => visitObs})
                          questions.push({:code => "data-visit_group-visit_form-autoreporte", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/autoreporte:label"]')[0].text.strip, :answer => visitAutoreporte})
                          questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_number_dengue:label"]')[0].text.strip, :answer => visitAutoreporteNumberDengue})
                          questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_number_chik:label"]')[0].text.strip, :answer => visitAutoreporteNumberChik})
                          questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_zika", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_reporte_number_zika:label"]')[0].text.strip, :answer => visitAutoreporteNumberZika})
                          questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_zika_number_pregnant:label"]')[0].text.strip, :answer => visitAutoreporteZikaNumberPregnant})
                          questions.push({:code => "data-visit_group-visit_form-symptoms", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms:label"]')[0].text.strip, :answer => visitAutoreporteSymptoms})
                          questions.push({:code => "data-visit_group-visit_form-symptoms_report-symptoms_gender", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms_report/symptoms_gender:label"]')[0].text.strip, :answer => visitAutoreporteSymptomsGender})
                          questions.push({:code => "data-visit_group-visit_form-symptoms_report-symptom_list" , :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms_report/symptom_list:label"]')[0].text.strip, :answer => visitAutoreporteSymptomsList})
                          worksheet.add_cell(4+inspectionIndex, 11, JSON.generate(questions))                     
                        end
                      end
                    end

                    #se crea temporalmente el archivo y luego se sube a la instancia S3 
                    # fileName = locations[locationId][0].split(',')[locationsHeader.index("data-location-final")].strip != "" ?  locations[locationId][0].split(',')[locationsHeader.index("data-location-final")][0..7] : locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code")].strip != "" ? locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code")][0..7] : locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code_manual")][0..7]
                    # puts "locationsHeader.index(data-location-final)].strip #{locations[locationId][0].split(',')[locationsHeader.index("data-location-final")].strip}"
                    # puts "locations[locationId][0].split(',')[8].strip #{locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code")].strip}"
                    # puts "locations[locationId][0].split(',')[9].strip #{locations[locationId][0].split(',')[locationsHeader.index("data-location-location_code_manual")]}"
                    
                    workbook.write("#{Rails.root}/#{fileName}.xlsx")
                    upload =  ActionDispatch::Http::UploadedFile.new({
                      :filename => "#{fileName}.xlsx",
                      :content_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                      :tempfile => File.new("#{Rails.root}/#{fileName}.xlsx")
                    })
                    
                    #usamos el archivo generado para el procesamiento normal del csv
                    API::V0::CsvReportsController.batch(:csv => upload,:file_name => "#{fileName}.xlsx", :username => (!User.find_by_username(locations[locationId][0].split(',')[locationsHeader.index("data-user_denguechat")]).eql? nil) ? locations[locationId][0].split(',')[locationsHeader.index("data-user_denguechat")] : defaultUser, :organization_id => organizationId)
                    #se elimina el archivo generado localmente
                    File.delete("#{Rails.root}/#{fileName}.xlsx") if File.exist?("#{Rails.root}/#{fileName}.xlsx")
                  end            
                end   
              end    
            end
          end
        end
      end
    end
    # OdkSpreadsheetParsingWorker.perform_in(1.day)
  end
end

