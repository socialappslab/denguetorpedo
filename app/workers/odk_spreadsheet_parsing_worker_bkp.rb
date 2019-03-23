# require "sidekiq"
# require 'json'
# require 'nokogiri'
#
# class OdkSpreadsheetParsingWorker
#   include Sidekiq::Worker
#   sidekiq_options :queue => :odk_parsing, :retry => true, :backtrace => true
#
#   def self.get_denguechat_to_form_mappings
#
#
#
#
#
#   end
#
#   def self.process_header(header_line)
#
#
#
#
#
#
#   end
#
#   def self.perform
#     locations = nil
#     inspectionsPerVisit = nil
#
#     Rails.logger.debug "[OdkSpreadsheetParsingWorker] Started the ODK synchronization ODK..."
#
#     # Read organizations grouped by the configuration parameters
#     organizations = Parameter.all.group_by do |parameter|
#       parameter.organization_id
#     end
#
#     organizations.each do |id, parameters|
#       organizations[id] = parameters.group_by { |parameter| parameter.key }
#       Rails.logger.debug "[OdkSpreadsheetParsingWorker] Parameters found for organization: "+id.to_s
#     end
#
#     # Parse the data URLs for each organization.
#     # Current version works only with three different CSVs, produced by an ODK collect form
#     # In all cases, 3 URLs to CSVs are needed:
#     # 1. A spreadsheet/csv with info about visited locations
#     # 2. A spreadsheet/csv with info about each visit for each location
#     # 3. A spreadsheet/csv with info about each different breeding site found in each visit
#     organizations.each do |organizationId, parameters|
#       # si la organizacion iterada cuenta con los parametros requeridos por el parser
#       if(!parameters["organization.data.visits.url"].nil? && !parameters["organization.data.locations.url"].nil? && !parameters["organization.data.inspections.url"].nil?)
#         Rails.logger.debug "Locations, visits and inspections URL found"
#         # Read the XML form spec
#         xmldoc = parameters["organization.data.xml-form"] != nil ? Nokogiri::HTML(open(parameters["organization.data.xml-form"][0].value)) : nil
#         # Read who the default user to upload this data should be
#         defaultUser = parameters["organization.sync.default-user"] != nil ? parameters["organization.sync.default-user"][0].value : nil
#
#         # Read locations
#         open(parameters["organization.data.locations.url"][0].value) do |locationsFile|
#             line.split(",")[15].split("\r")[0]
#           end
#         end
#
#         #se obtienen las inspecciones agrupadas por visitas
#         open(parameters["organization.data.inspections.url"][0].value) do |inspectionsFile|
#           inspectionsPerVisit = inspectionsFile.read.split($/)[1..-1].group_by do |line|
#             line.split(",")[9]
#           end
#         end
#
#         #se obtienen las visitas
#         open(parameters["organization.data.visits.url"][0].value) do |visitsFile|
#
#           visitsFile.read.split($/)[1..-1].each_with_index do |visit,visitsIndex|
#
#             visitArray = visit.split(",")
#
#
#
#             visitId = visitArray[16]
#             locationId = visitArray[17]
#
#             #si el id de la visita no esta cargado en la planilla, se descarta la misma
#             if(visitId != "")
#               #si no existen inspecciones para la visita iterada, se descarta la misma
#               if(!inspectionsPerVisit[visitId].eql? nil && inspectionsPerVisit[visitId].length > 0)
#                 workbook = RubyXL::Workbook.new
#                 worksheet = workbook[0]
#                 header = ["Fecha de visita (YYYY-MM-DD)" ,"Auto-reporte dengue/chik",	"Tipo de criadero",	"Localización", "¿Protegido?", "¿Abatizado?", "¿Larvas?", "¿Pupas?", "¿Foto de criadero?", "Fecha de eliminación (YYYY-MM-DD)",	"¿Foto de eliminación?", "Comentarios sobre tipo y/o eliminación"]
#                 header.each_with_index  do |string, index|
#                   worksheet.add_cell(3, index, string)
#                 end
#
#
#                 visitDate =  visitArray[9].insert(6,'20')
#                 visitStatus =  visitArray[10]
#                 visitHostGender =  visitArray[11]
#                 visitHostAge =  visitArray[12]
#                 visitServicesLarvicide =   visitArray[13].strip != "" ? visitArray[13] : visitArray[33]
#                 visitServicesFumigation =   visitArray[14].strip != "" ? visitArray[14] : visitArray[34]
#                 visitObs =  visitArray[15].strip != "" ? visitArray[15] : visitArray[24]
#                 visitAutoreporte =  visitArray[16].strip != "" ? visitArray[16] : visitArray[25]
#                 visitAutoreporteNumberDengue =  visitArray[17].strip != "" ? visitArray[17] : visitArray[26]
#                 visitAutoreporteNumberChik =  visitArray[18].strip != "" ? visitArray[18] : visitArray[27]
#                 visitAutoreporteNumberZika =  visitArray[19].strip != "" ? visitArray[19] : visitArray[28]
#                 visitAutoreporteZikaNumberPregnant =  visitArray[20].strip != "" ? visitArray[20] : visitArray[29]
#                 visitAutoreporteSymptoms = visitArray[21].strip != "" ? visitArray[21] : visitArray[30]
#                 visitAutoreporteSymptomsGender = visitArray[22].strip != "" ? visitArray[22] : visitArray[31]
#                 visitAutoreporteSymptomsList = visitArray[23].strip != "" ? visitArray[23] : visitArray[32]
#                 questions = []
#
#                 inspectionsPerVisit[visitId].each_with_index do |inspection,inspectionIndex|
#
#                   tempInspection = inspection.split(",")
#                   worksheet.add_cell(4+inspectionIndex, 0, visitDate)
#                   worksheet.add_cell(4+inspectionIndex, 2, tempInspection[0])
#                   worksheet.add_cell(4+inspectionIndex, 4, tempInspection[2])
#                   worksheet.add_cell(4+inspectionIndex, 6, tempInspection[3])
#                   worksheet.add_cell(4+inspectionIndex, 7, tempInspection[4])
#                   worksheet.add_cell(4+inspectionIndex, 9, tempInspection[7])
#
#                   #por cada inspeccion, se genera un campo denominado questions con formato jsonb, en el mismo se almacenan las preguntas extraidas desde el documento xml y las respuestas correspondientes, siempre que el mismo exista
#                   if(xmldoc != nil)
#                     questions.push({:code => "data-visit_group-location_status", :body => xmldoc.xpath('//*[@id="/data/visit_group/location_status:label"]')[0].text.strip, :answer => visitStatus})
#                     questions.push({:code => "data-visit_group-visit_form-visit-visit_host_gender", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit/visit_host_gender:label"]')[0].text.strip, :answer => visitHostGender})
#                     questions.push({:code => "data-visit_group-visit_form-visit-visit_host_age", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit/visit_host_age:label"]')[0].text.strip, :answer => visitHostAge})
#                     questions.push({:code => "data-visit_group-visit_form-services_fumigation", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/services_fumigation:label"]')[0].text.strip, :answer => visitServicesFumigation})
#                     questions.push({:code => "data-visit_group-visit_form-services_larvicide", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/services_larvicide:label"]')[0].text.strip, :answer => visitServicesLarvicide})
#                     questions.push({:code => "data-visit_group-visit_form-visit_obs", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit_obs:label"]')[0].text.strip, :answer => visitObs})
#                     questions.push({:code => "data-visit_group-visit_form-autoreporte", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/autoreporte:label"]')[0].text.strip, :answer => visitAutoreporte})
#                     questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_number_dengue:label"]')[0].text.strip, :answer => visitAutoreporteNumberDengue})
#                     questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_number_chik:label"]')[0].text.strip, :answer => visitAutoreporteNumberChik})
#                     questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_zika", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_reporte_number_zika:label"]')[0].text.strip, :answer => visitAutoreporteNumberZika})
#                     questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_zika_number_pregnant:label"]')[0].text.strip, :answer => visitAutoreporteZikaNumberPregnant})
#                     questions.push({:code => "data-visit_group-visit_form-symptoms", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms:label"]')[0].text.strip, :answer => visitAutoreporteSymptoms})
#                     questions.push({:code => "data-visit_group-visit_form-symptoms_report-symptoms_gender", :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms_report/symptoms_gender:label"]')[0].text.strip, :answer => visitAutoreporteSymptomsGender})
#                     questions.push({:code => "data-visit_group-visit_form-symptoms_report-symptom_list" , :body => xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms_report/symptom_list:label"]')[0].text.strip, :answer => visitAutoreporteSymptomsList})
#                     worksheet.add_cell(4+inspectionIndex, 11, JSON.generate(questions))
#                   end
#
#                 end
#
#                 #se crea temporalmente el archivo y luego se sube a la instancia S3
#
#                 fileName = locations[locationId][0].split(',')[6].trim != "" ?  locations[locationId][0].split(',')[6][0..7] : locations[locationId][0].split(',')[7].trim != "" ? locations[locationId][0].split(',')[7][0..7] : locations[locationId][0].split(',')[8][0..7]
#                 workbook.write("#{Rails.root}/#{fileName}.xlsx")
#                 upload =  ActionDispatch::Http::UploadedFile.new({
#                   :filename => "#{fileName}.xlsx",
#                   :content_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
#                   :tempfile => File.new("#{Rails.root}/#{fileName}.xlsx")
#                 })
#
#                 #usamos el archivo generado para el procesamiento normal del csv
#                 #API::V0::CsvReportsController.batch(:csv => upload,:file_name => "#{fileName}.xlsx", :username => defaultUser, :organization_id => organizationId)
#                 #se elimina el archivo generado localmente
#                 #File.delete("#{Rails.root}/#{fileName}.xlsx") if File.exist?("#{Rails.root}/#{fileName}.xlsx")
#               end
#             end
#           end
#         end
#       end
#     end
#     OdkSpreadsheetParsingWorker.perform_in(1.day)
#   end
# end
#
