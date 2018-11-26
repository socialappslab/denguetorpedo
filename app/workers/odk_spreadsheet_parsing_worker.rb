require "sidekiq"
require 'json'
require 'nokogiri'

class OdkSpreadsheetParsingWorker 
  include Sidekiq::Worker
  sidekiq_options :queue => :odk_parsing, :retry => true, :backtrace => true
  
  def perform 
    locations = nil
    inspectionsPerVisit = nil
    organizations = Parameter.all.group_by do |parameter|
      parameter.organization_id
    end
    organizations.each do |id, parameters|
      organizations[id] = parameters.group_by { |parameter| parameter.key }
    end
    organizations.each do |organizationId, parameters|
      if(!parameters["organization.data.visits.url"].nil? && !parameters["organization.data.locations.url"].nil? && !parameters["organization.data.inspections.url"].nil?)
        if(Organization.find(organizationId).name == "TopaDengue.PY")
          xmldoc = parameters["organization.data.xml-form"] != nil ? Nokogiri::HTML(open(parameters["organization.data.xml-form"][0].value)) : nil
          defaultUser = parameters["organization.sync.default-user"] != nil ? parameters["organization.sync.default-user"][0].value : nil
          
          open(parameters["organization.data.locations.url"][0].value) do |locationsFile|
            locations = locationsFile.read.split($/)[1..-1].group_by do |line| 
              line.split(",")[15].split("\r")[0]
            end
          end 

          open(parameters["organization.data.inspections.url"][0].value) do |inspectionsFile|
            inspectionsPerVisit = inspectionsFile.read.split($/)[1..-1].group_by do |line| 
              line.split(",")[9]
            end
          end

          open(parameters["organization.data.visits.url"][0].value) do |visitsFile|
            visitsFile.read.split($/)[1..-1].each_with_index do |visit,visitsIndex| 
              
              visitArray = visit.split(",")
              visitId = visitArray[16]
              locationId = visitArray[17]
      
              if(visitId != "" && visitsIndex <= 200)      
                workbook = RubyXL::Workbook.new
                worksheet = workbook[0]
                header = ["Fecha de visita (YYYY-MM-DD)" ,"Auto-reporte dengue/chik",	"Tipo de criadero",	"Localización", "¿Protegido?", "¿Abatizado?", "¿Larvas?", "¿Pupas?", "¿Foto de criadero?", "Fecha de eliminación (YYYY-MM-DD)",	"¿Foto de eliminación?", "Comentarios sobre tipo y/o eliminación"]
                header.each_with_index  do |string, index| 
                  worksheet.add_cell(3, index, string) 
                end
      
                visitDate =  visitArray[0].insert(6,'20')
                visitStatus =  visitArray[1]
                visitHostGender =  visitArray[2]
                visitHostAge =  visitArray[3]
                visitServicesFumigation =  visitArray[4]
                visitServicesLarvicide=  visitArray[5]
                visitObs =  visitArray[6]
                visitAutoreporte =  visitArray[7]
                visitAutoreporteNumberDengue =  visitArray[8]
                visitAutoreporteNumberChik =  visitArray[9]
                visitAutoreporteNumberZika =  visitArray[10]
                visitAutoreporteZikaNumberPregnant = visitArray[11]
                visitAutoreporteSymptoms = visitArray[12]
                visitAutoreporteSymptomsGender = visitArray[13]
                visitAutoreporteSymptomsList = visitArray[14]
            
                if(!inspectionsPerVisit[visitId].eql? nil && inspectionsPerVisit[visitId].length > 0)
                  questions = []             
      
                  inspectionsPerVisit[visitId].each_with_index do |inspection,inspectionIndex|
                    questions.push({:code => "data-visit_group-location_status", :body =>  xmldoc.xpath('//*[@id="/data/visit_group/location_status:label"]')[0].text.strip, :answer => visitStatus})
                    questions.push({:code => "data-visit_group-visit_form-visit-visit_host_gender", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit/visit_host_gender:label"]')[0].text.strip : "", :answer => visitHostGender})
                    questions.push({:code => "data-visit_group-visit_form-visit-visit_host_age", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit/visit_host_age:label"]')[0].text.strip : "", :answer => visitHostAge})
                    questions.push({:code => "data-visit_group-visit_form-services_fumigation", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/services_fumigation:label"]')[0].text.strip : "", :answer => visitServicesFumigation})
                    questions.push({:code => "data-visit_group-visit_form-services_larvicide", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/services_larvicide:label"]')[0].text.strip : "", :answer => visitServicesLarvicide})
                    questions.push({:code => "data-visit_group-visit_form-visit_obs", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/visit_obs:label"]')[0].text.strip : "", :answer => visitObs})
                    questions.push({:code => "data-visit_group-visit_form-autoreporte", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/autoreporte:label"]')[0].text.strip : "", :answer => visitAutoreporte})
                    questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_number_dengue:label"]')[0].text.strip : "", :answer => visitAutoreporteNumberDengue})
                    questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_number_chik:label"]')[0].text.strip : "", :answer => visitAutoreporteNumberChik})
                    questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_number_zika", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_reporte_number_zika:label"]')[0].text.strip : "", :answer => visitAutoreporteNumberZika})
                    questions.push({:code => "data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/auto_report_numbers/auto_report_zika_number_pregnant:label"]')[0].text.strip : "", :answer => visitAutoreporteZikaNumberPregnant})
                    questions.push({:code => "data-visit_group-visit_form-symptoms", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms:label"]')[0].text.strip : "", :answer => visitAutoreporteSymptoms})
                    questions.push({:code => "data-visit_group-visit_form-symptoms_report-symptoms_gender", :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms_report/symptoms_gender:label"]')[0].text.strip : "", :answer => visitAutoreporteSymptomsGender})
                    questions.push({:code => "data-visit_group-visit_form-symptoms_report-symptom_list" , :body => xmldoc != nil ? xmldoc.xpath('//*[@id="/data/visit_group/visit_form/symptoms_report/symptom_list:label"]')[0].text.strip : "", :answer => visitAutoreporteSymptomsList})
      
                    tempInspection = inspection.split(",")
                    worksheet.add_cell(4+inspectionIndex, 0, visitDate) 
                    worksheet.add_cell(4+inspectionIndex, 2, tempInspection[0]) 
                    worksheet.add_cell(4+inspectionIndex, 4, tempInspection[2])
                    worksheet.add_cell(4+inspectionIndex, 6, tempInspection[3]) 
                    worksheet.add_cell(4+inspectionIndex, 7, tempInspection[4]) 
                    worksheet.add_cell(4+inspectionIndex, 9, tempInspection[7]) 
                    worksheet.add_cell(4+inspectionIndex, 11, JSON.generate(questions)) 
                  end

                  workbook.write("#{Rails.root}/#{locations[locationId][0].split(',')[6]}.xlsx")
                  upload =  ActionDispatch::Http::UploadedFile.new({
                    :filename => "#{locations[locationId][0].split(',')[6]}.xlsx",
                    :content_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    :tempfile => File.new("#{Rails.root}/#{locations[locationId][0].split(',')[6]}.xlsx")
                  })
                
                  API::V0::CsvReportsController.batch(:csv => upload,:file_name => "#{locations[locationId][0].split(',')[6]}.xlsx", :username => defaultUser, :organization_id => organizationId)
                  File.delete("#{Rails.root}/#{locations[locationId][0].split(',')[6]}.xlsx") if File.exist?("#{Rails.root}/#{locations[locationId][0].split(',')[6]}.xlsx")
                end              
              end       
            end
          end
        end
      end
    end
    OdkSpreadsheetParsingWorker.perform_in(1.day)
  end
end

