require "sidekiq"
require 'json'
require 'nokogiri'

class OdkSpreadsheetParsingWorker 
  include Sidekiq::Worker
  sidekiq_options :queue => :odk_parsing, :retry => true, :backtrace => true

  @@dengue_chat_csv_header_keys = ["Fecha de visita (YYYY-MM-DD)" ,"Auto-reporte dengue/chik",	"Tipo de criadero",
                                   "Localización", "¿Protegido?", "¿Abatizado?", "¿Larvas?", "¿Pupas?",
                                   "¿Foto de criadero?", "Fecha de eliminación (YYYY-MM-DD)",	"¿Foto de eliminación?",
                                   "Comentarios sobre tipo y/o eliminación", "Foto de larvas", "Respuestas Adicionales",
                                   "Form User", "Form Team"]
  @@parameter_keys = {
      :locationsUrlKey => "organization.data.locations.url",
      :visitsUrlKey => "organization.data.visits.url",
      :inspectionsUrlKey => "organization.data.inspections.url",
      :xmlFormUrlKey => "organization.data.xml-form",
      :defaultUserKey => "organization.sync.default-user"
  }

  @@location_fields_dict = {
      :lFormId => ["KEY"],
      :lName => ["data-location-location_code_manual", "data-location-location_code", "data-location_data-location_code_manual"],
      :lTeam => ["data-phonenumber"],
      :lUser => ["data-username"],
      :lStartTime => ["data-start"],
      :lEndTime => ["data-end"],
      :lFormDate => ["data-today"],
      :lDeviceId => ["data-deviceid"]
  }

  @@visit_fields_dict = {
      :vFormId => ["KEY"],
      :vLocationFormParent => ["PARENT_KEY"],
      :vDate => ["data-visit_group-visit_date"], # "Fecha de visita (YYYY-MM-DD)" in Excel CSV
      :vStatus => ["data-visit_group-location_status"], # Not available in original Excel CSV
      :vHostGender => ["data-visit_group-visit_form-visit-visit_host_gender"], # Not available in original Excel CSV
      :vHostAge => ["data-visit_group-visit_form-visit-visit_host_age"], # Not available in original Excel CSV
      :vLarvicide => ["data-visit_group-visit_form-services_larvicide","data-visit_group-visit_form-visit-services_larvicide"], # Not available in original Excel CSV
      :vFumigation => ["data-visit_group-visit_form-services_fumigation","data-visit_group-visit_form-visit-services_fumigation"], # Not available in original Excel CSV
      :vObs => ["data-visit_group-visit_form-visit_obs","data-visit_group-visit_form-visit-visit_obs"],
      :vAutorep => ["data-visit_group-visit_form-autoreporte","data-visit_group-visit_form-visit-autoreporte"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepDengue => ["data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue","data-visit_group-visit_form-visit-auto_report_numbers-auto_report_number_dengue"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepChik => ["data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik","data-visit_group-visit_form-visit-auto_report_numbers-auto_report_number_chik"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepZika => ["data-visit_group-visit_form-auto_report_numbers-auto_reporte_number_zika","data-visit_group-visit_form-visit-auto_report_numbers-auto_reporte_number_zika"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepPregnant => ["data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant","data-visit_group-visit_form-visit-auto_report_numbers-auto_report_zika_number_pregnant"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepSymptoms => ["data-visit_group-visit_form-symptoms","data-visit_group-visit_form-visit-symptoms"], # Not available in original Excel CSV
      :vAutorepSymptomsGender => ["data-visit_group-visit_form-symptoms_report-symptoms_gender","data-visit_group-visit_form-visit-symptoms_report-symptoms_gender"], # Not available in original Excel CSV
      :vAutorepSymptomsList => ["data-visit_group-visit_form-symptoms_report-symptom_list","data-visit_group-visit_form-visit-symptoms_report-symptom_list"] # Not available in original Excel CSV
  }

  @@inspection_fields_dict = {
      :iFormId => ["KEY"],
      :iVisitFormParent => ["PARENT_KEY"],
      :iBRSCode => ["data-visit_group-inspection-breeding_site_code"], # "Tipo de criadero" in original Excel CSV
      :iBRSCodeAmount => ["data-visit_group-inspection-breeding_site_amount"], # Tipo de criadero" in original Excel CSV
      :iLocalization => ["data-visit_group-inspection-br_localization"], # "Localización",
      :iProtected => ["data-visit_group-inspection-br_protected"], # "¿Protegido?"
      :iLarvicide => ["data-visit_group-inspection-br_larvicide"], # "¿Abatizado?"
      :iLarvae => ["data-visit_group-inspection-br_larvae"], # "¿Larvas?",
      :iPupae => ["data-visit_group-inspection-br_pupae"], # "¿Pupas?",
      :iPicture => ["data-visit_group-inspection-br_picture"], # "¿Foto de criadero?",
      :iEliminationDate => ["data-visit_group-inspection-br_elimination_date"], # "Fecha de eliminación (YYYY-MM-DD)",
      :iEliminationPhoto => ["data-visit_group-inspection-br_elimination_picture"], # "¿Foto de eliminación?",
      :iLarvaePicture => ["data-visit_group-inspection-br_larvae_picture"],
      :iObs => ["data-visit_group-inspection-breeding_site_description"] # "Comentarios sobre tipo y/o eliminación"]
  }

  # Prepare LOCATION field keys to retrieve from CSV files
  @@lFormIdKeys = @@location_fields_dict[:lFormId]
  @@lNameKeys = @@location_fields_dict[:lName]
  @@lTeamKeys = @@location_fields_dict[:lTeam]
  @@lUserKeys = @@location_fields_dict[:lUser]
  @@lStartTimeKeys = @@location_fields_dict[:lStartTime]
  @@lEndTimeKeys = @@location_fields_dict[:lEndTime]
  @@lFormDateKeys = @@location_fields_dict[:lFormDate]
  @@lDeviceIdKeys = @@location_fields_dict[:lDeviceId]
  # Prepare VISIT field keys to retrieve from CSV files
  @@vStatusKeys = @@visit_fields_dict[:vStatus] # => if 'E', process visit
  @@vFormIdKeys = @@visit_fields_dict[:vFormId]
  @@vParentFormIdKeys = @@visit_fields_dict[:vLocationFormParent]
  @@vDateKeys = @@visit_fields_dict[:vDate] # => header[0] = "Fecha de visita (YYYY-MM-DD)"
  @@vAutorepKeys = @@visit_fields_dict[:vAutorep] # => if 1, process the AUTOREPORTE columns
  @@vAutorepDengueKeys = @@visit_fields_dict[:vAutorepDengue] # => header[1] => "Auto-reporte dengue/chik" Example: C(m20)D(f3,f010)
  @@vAutorepChikKeys = @@visit_fields_dict[:vAutorepChik] # => header[1] => "Auto-reporte dengue/chik" Example: C(m20)D(f3,f010)
  @@vAutorepZikaKeys = @@visit_fields_dict[:vAutorepZika] # => header[1] => "Auto-reporte dengue/chik" Example: C(m20)D(f3,f010)
  @@vObsKeys = @@visit_fields_dict[:vObs ] # => header[11] => "Comentarios sobre tipo y/o eliminación"
  @@vHostGenderKeys = @@visit_fields_dict[:vHostGender] # => questions
  @@vHostAgeKeys = @@visit_fields_dict[:vHostAge] # => questions
  @@vLarvicideKeys = @@visit_fields_dict[:vLarvicide] # => questions
  @@vFumigationKeys = @@visit_fields_dict[:vFumigation] # => questions
  @@vAutorepPregnantKeys = @@visit_fields_dict[:vAutorepPregnant] # => questions
  @@vAutorepSympKeys = @@visit_fields_dict[:vAutorepSymptoms] # => questions
  @@vAutorepSympGenderKeys = @@visit_fields_dict[:vAutorepSymptomsGender] # => questions
  @@vAutorepSympListKeys = @@visit_fields_dict[:vAutorepSymptomsList] # => questions
  # Prepare INSPECTION field keys to retrieve from CSV files
  @@iVisitIdKeys = @@inspection_fields_dict[:iVisitFormParent]
  @@brsCodeKeys = @@inspection_fields_dict[:iBRSCode]
  @@brsCodeAmountKeys = @@inspection_fields_dict[:iBRSCodeAmount]
  @@brsLocalizationKeys = @@inspection_fields_dict[:iLocalization]
  @@brsProtectedKeys = @@inspection_fields_dict[:iProtected]
  @@brsLarvicideKeys = @@inspection_fields_dict[:iLarvicide]
  @@brsLarvaeKeys = @@inspection_fields_dict[:iLarvae]
  @@brsPupaeKeys = @@inspection_fields_dict[:iPupae]
  @@brsEliminationDateKeys = @@inspection_fields_dict[:iEliminationDate]
  @@brsEliminationPhotoKeys = @@inspection_fields_dict[:iEliminationPhoto]
  @@brsObsKeys = @@inspection_fields_dict[:iObs]
  @@brsPictureUrlKeys = @@inspection_fields_dict[:iPicture]
  @@brsLarvaPictureUrlKeys = @@inspection_fields_dict[:iPicture]

  # Extract the data on a single cell of a row in the record, given a set of possible keys with their positions
  # If the key does not exist among the headers, return an empty string
  def self.extract_data_from_record(recordArray, headerArray, possibleKeys, indexOfKeyToUse)
    key = possibleKeys[indexOfKeyToUse]
    if (!key.nil? && key != "")
      fieldPosition = headerArray.index(key)
      if (!fieldPosition.nil? && fieldPosition > -1)
        return recordArray[fieldPosition]
      else
        return ""
      end
    else
      return ""
    end
  end

  # Given an xmlform spec and xpath, retrieve the text related to that field
  def self.extract_desc_from_xmlform(xmldoc, xpath)
    queryResult = xmldoc.xpath(xpath)
    if !queryResult.nil?
      value = queryResult[0]
      if !value.nil?
        return value.text.strip
      else
        return xpath
      end
    else
      return xpath
    end
  end

  def self.key_to_xpath(key)
    return key.gsub(/-/,'/')
  end

  def self.extract_record_array_by_key(groupedLines, key, separator)
    lines = groupedLines[key]
    if (!lines.nil?)
      return lines[0].split(separator)
    end
  end

  # REDIS methods
  # We use redist to persist form IDs and other data that we do not want to sync again
  def self.persist_key_to_redis(organizationId, type, syncStatus, key)
    $redis_pool.with do |redis|
      redis.sadd("organization:#{organizationId}:odk:sync:#{type}:#{syncStatus}", "#{key}")
    end
  end

  def self.read_key_from_redis(organizationId, type, syncStatus, key)
    $redis_pool.with do |redis|
      redis.sismember("organization:#{organizationId}:odk:sync:#{type}:#{syncStatus}", "#{key}")
    end
  end

  def self.read_all_keys_from_redis(organizationId, type, syncStatus)
    $redis_pool.with do |redis|
      redis.smembers("organization:#{organizationId}:odk:sync:#{type}:#{syncStatus}")
    end
  end

  def self.remove_key_from_redis(organizationId, type, syncStatus, key)
    $redis_pool.with do |redis|
      redis.srem("organization:#{organizationId}:odk:sync:#{type}:#{syncStatus}", key)
    end
  end

  def self.read_csv_and_group_by(url, groupFieldKeys, indexOfKey)
    finalFile = { :header => [], :fileGroupedByKey => [] }
    open(url) do |file|
      tempFile = file.read
      finalFile[:header] = tempFile.split($/)[0].sub(/\r/,'').split(",")
      columnOfKey = finalFile[:header].index(groupFieldKeys[indexOfKey])
      finalFile[:fileGroupedByKey] = tempFile.split($/)[1..-1].group_by do |line|
        line.split(",")[columnOfKey].split("\r")[0]
      end
    end
    return finalFile
  end

  def self.prepare_and_process_denguechat_csv(organizationId, xmldoc, locationArray, locationsHeader, visitArray, visitsHeader, visitIndex,
      inspectionsArray, inspectionsHeader, worksheet, visitStartingRow)
    worksheetRowPointer = visitStartingRow
    visitId = extract_data_from_record(visitArray, visitsHeader, @@vFormIdKeys, 0)
    visitParentFormId = extract_data_from_record(visitArray, visitsHeader, @@vParentFormIdKeys, 0)
    inspCount = inspectionsArray.nil? ? 0 : inspectionsArray.length
    visitStatus = extract_data_from_record(visitArray,visitsHeader, @@vStatusKeys, 0)
    lFormUser = extract_data_from_record(locationArray, locationsHeader, @@lUserKeys, 0)
    lFormTeam = extract_data_from_record(locationArray, locationsHeader, @@lTeamKeys, 0)
    lFormStartTime = extract_data_from_record(locationArray, locationsHeader, @@lStartTimeKeys, 0)
    lFormEndTime = extract_data_from_record(locationArray, locationsHeader, @@lEndTimeKeys, 0)
    lFormDate = extract_data_from_record(locationArray, locationsHeader, @@lFormDateKeys, 0)
    lFormDeviceId = extract_data_from_record(locationArray, locationsHeader, @@lDeviceIdKeys, 0)

    # Rails.logger.debug "[OdkSpreadsheetParsingWorker] About to process #{inspCount.to_s} inspections for visit #{visitId}"
    # Extract data related to the VISIT from the visitArray
    # ToDo: once integrated and with data cleaned, eliminate or think  of better way to handle  fallbacks
    vDate = extract_data_from_record(visitArray, visitsHeader, @@vDateKeys, 0).insert(6, '20')
    vAutorep = extract_data_from_record(visitArray, visitsHeader, @@vAutorepKeys, 0).strip != "" ?
                   extract_data_from_record(visitArray, visitsHeader, @@vAutorepKeys, 0) :
                   extract_data_from_record(visitArray, visitsHeader, @@vAutorepKeys, 1)
    vAutorepDengue = extract_data_from_record(visitArray, visitsHeader, @@vAutorepDengueKeys, 0).strip != "" ?
                         extract_data_from_record(visitArray, visitsHeader, @@vAutorepDengueKeys, 0) :
                         extract_data_from_record(visitArray, visitsHeader, @@vAutorepDengueKeys, 1)
    vAutorepChik = extract_data_from_record(visitArray, visitsHeader, @@vAutorepChikKeys, 0).strip != "" ?
                       extract_data_from_record(visitArray, visitsHeader, @@vAutorepChikKeys, 0) :
                       extract_data_from_record(visitArray, visitsHeader, @@vAutorepChikKeys, 1)
    vAutorepZika = extract_data_from_record(visitArray, visitsHeader, @@vAutorepZikaKeys, 0).strip != "" ?
                       extract_data_from_record(visitArray, visitsHeader, @@vAutorepZikaKeys, 0) :
                       extract_data_from_record(visitArray, visitsHeader, @@vAutorepZikaKeys, 1)
    vAutorepFinal = ""
    if (vAutorep.strip == "1")
      if (vAutorepDengue != "" && vAutorepDengue != "0")
        vAutorepFinal = vAutorepFinal + vAutorepDengue + "D"
      end
      if (vAutorepChik != "" && vAutorepChik != "0")
        vAutorepFinal = vAutorepFinal + vAutorepChik + "C"
      end
      if (vAutorepZika != "" && vAutorepZika != "0")
        vAutorepFinal = vAutorepFinal + vAutorepZika + "Z"
      end
    end
    visitObs =  extract_data_from_record(visitArray, visitsHeader, @@vObsKeys, 0).strip != "" ?
                    extract_data_from_record(visitArray, visitsHeader, @@vObsKeys, 0) :
                    extract_data_from_record(visitArray, visitsHeader, @@vObsKeys, 0)
    visitHostGender =  extract_data_from_record(visitArray, visitsHeader, @@vHostGenderKeys, 0)
    visitHostAge =  extract_data_from_record(visitArray, visitsHeader, @@vHostAgeKeys, 0)
    visitLarvicide =   extract_data_from_record(visitArray, visitsHeader, @@vLarvicideKeys, 0).strip != "" ?
                           extract_data_from_record(visitArray, visitsHeader, @@vLarvicideKeys, 0) :
                           extract_data_from_record(visitArray, visitsHeader, @@vLarvicideKeys, 1)
    visitServices =   extract_data_from_record(visitArray, visitsHeader, @@vFumigationKeys, 0).strip != "" ?
                          extract_data_from_record(visitArray, visitsHeader, @@vFumigationKeys, 0) :
                          extract_data_from_record(visitArray, visitsHeader, @@vFumigationKeys, 1)
    visitAutorepPregnant =  extract_data_from_record(visitArray, visitsHeader, @@vAutorepPregnantKeys, 0).strip != "" ?
                                extract_data_from_record(visitArray, visitsHeader, @@vAutorepPregnantKeys, 0) :
                                extract_data_from_record(visitArray, visitsHeader, @@vAutorepPregnantKeys, 1)
    visitAutorepSymptoms = extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympKeys, 0).strip != "" ?
                               extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympKeys, 0) :
                               extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympKeys, 1)
    visitAutorepSymptomsGender = extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympGenderKeys, 0).strip != "" ?
                                     extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympGenderKeys, 0) :
                                     extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympGenderKeys, 1)
    visitAutorepSymptomsList = extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympListKeys, 0).strip != "" ?
                                   extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympListKeys, 0) :
                                   extract_data_from_record(visitArray, visitsHeader, @@vAutorepSympListKeys, 1)
    questions = []

    # Insert VISIT DATA into the workbook
    # Visit date and visit related data is included only in the first row.
    # Subsequent rows of the same visit should remain empty in these columns
    worksheet.add_cell(worksheetRowPointer, 0, vDate) # "Fecha de visita (YYYY-MM-DD)" in DengueChat Excel CSV Form
    worksheet.add_cell(worksheetRowPointer, 1, vAutorepFinal) # "Auto-reporte dengue/chik" in DengueChat Excel CSV Form
    # For each visit, a JSONB data record is generated to contain all the data that was collected
    # but that is not related to data fields in the model of DengueChat.
    # They are stored in the questions field of the DC model, using the XMLForm specs to include both
    # the form field name and the form field description (i.e., the actual question that was made)
    if(xmldoc != nil )
      questions.push({:code => @@vFormIdKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vFormIdKeys[0])), :answer => visitId})
      questions.push({:code => @@vParentFormIdKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vParentFormIdKeys[0])), :answer => visitParentFormId})
      questions.push({:code => @@vStatusKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vStatusKeys[0])), :answer => visitStatus})
      questions.push({:code => @@vHostGenderKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vHostGenderKeys[0])), :answer => visitHostGender})
      questions.push({:code => @@vHostAgeKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vHostAgeKeys[0])), :answer => visitHostAge})
      questions.push({:code => @@vFumigationKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vFumigationKeys[0])), :answer => visitServices})
      questions.push({:code => @@vLarvicideKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vLarvicideKeys[0])), :answer => visitLarvicide})
      questions.push({:code => @@vObsKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vObsKeys[0])), :answer => visitObs})
      questions.push({:code => @@vAutorepKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepKeys[0])), :answer => vAutorep})
      questions.push({:code => @@vAutorepDengueKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepDengueKeys[0])), :answer => vAutorepDengue})
      questions.push({:code => @@vAutorepChikKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepChikKeys[0])), :answer => vAutorepChik})
      questions.push({:code => @@vAutorepZikaKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepZikaKeys[0])), :answer => vAutorepZika})
      questions.push({:code => @@vAutorepPregnantKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepPregnantKeys[0])), :answer => visitAutorepPregnant})
      questions.push({:code => @@vAutorepSympKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepSympKeys[0])), :answer => visitAutorepSymptoms})
      questions.push({:code => @@vAutorepSympGenderKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepSympGenderKeys[0])), :answer => visitAutorepSymptomsGender})
      questions.push({:code => @@vAutorepSympListKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@vAutorepSympListKeys[0])), :answer => visitAutorepSymptomsList})
      questions.push({:code => @@lFormDateKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@lFormDateKeys[0])), :answer => lFormDate})
      questions.push({:code => @@lStartTimeKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@lStartTimeKeys[0])), :answer => lFormStartTime})
      questions.push({:code => @@lEndTimeKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@lEndTimeKeys[0])), :answer => lFormEndTime})
      questions.push({:code => @@lDeviceIdKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(@@lDeviceIdKeys[0])), :answer => lFormDeviceId})
      worksheet.add_cell(worksheetRowPointer, 13, JSON.generate(questions)) # "Respuestas Adicionales" NOT in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 14, lFormUser)
      worksheet.add_cell(worksheetRowPointer, 15, lFormTeam)

    end

    if inspCount > 0
      inspectionsDuplicateArrayController = []
      inspectionsArray.each_with_index do |inspection,inspectionIndex|
        worksheetRowPointer = visitStartingRow+inspectionIndex
        tempInspection = inspection.split(",")
        # Filter of duplicated inspections
        inspectionFormId = extract_data_from_record(tempInspection, inspectionsHeader, @@inspection_fields_dict[:iFormId], 0)
        if !inspectionsDuplicateArrayController.include? inspectionFormId
          inspectionsDuplicateArrayController.push(inspectionFormId)

          # Extracting data from inspection related fields
          brsCode = extract_data_from_record(tempInspection, inspectionsHeader, @@brsCodeKeys, 0) #tipo de criadero data-visit_group-inspection-breeding_site_code
          brsCodeAmount = extract_data_from_record(tempInspection, inspectionsHeader, @@brsCodeAmountKeys, 0) #tipo de criadero data-visit_group-inspection-breeding_site_code
          brsCodeFinal = brsCode+brsCodeAmount.to_s
          if (visitIndex == 0 && inspCount == 0 && (brsCode.nil? || brsCode.strip == ""))
            brsCodeFinal = "N" # If a visit has only one empty inspection record, then these is mapped as a negative (N) breeding site
          end
          brsLocalization = extract_data_from_record(tempInspection, inspectionsHeader, @@brsLocalizationKeys, 0)
          brsProtected = extract_data_from_record(tempInspection, inspectionsHeader, @@brsProtectedKeys, 0) #protegido? data-visit_group-inspection-br_protected
          brsLarvicide = extract_data_from_record(tempInspection, inspectionsHeader, @@brsLarvicideKeys, 0)
          brsLarvae = extract_data_from_record(tempInspection, inspectionsHeader, @@brsLarvaeKeys, 0) #larvas? data-visit_group-inspection-br_larvae
          brsPupae = extract_data_from_record(tempInspection, inspectionsHeader, @@brsPupaeKeys, 0) #pupas? data-visit_group-inspection-br_pupae
          brsEliminationDate = extract_data_from_record(tempInspection, inspectionsHeader,@@brsEliminationDateKeys, 0) #fecha de eliminacion data-visit_group-inspection-br_elimination_date
          brsEliminationPhoto = extract_data_from_record(tempInspection, inspectionsHeader, @@brsEliminationPhotoKeys, 0)
          brsObs = extract_data_from_record(tempInspection, inspectionsHeader, @@brsObsKeys, 0)
          brsPictureUrl = extract_data_from_record(tempInspection, inspectionsHeader, @@brsPictureUrlKeys, 0)
          brsLarvaPictureUrl = extract_data_from_record(tempInspection, inspectionsHeader, @@brsLarvaPictureUrlKeys, 0)
          worksheet.add_cell(worksheetRowPointer, 2, brsCodeFinal) # 	"Tipo de criadero" in DengueChat Excel CSV Form
          worksheet.add_cell(worksheetRowPointer, 3, brsLocalization) # 3 => "Localización" => not available in current ODK Form
          worksheet.add_cell(worksheetRowPointer, 4, brsProtected) # "¿Protegido?" in DengueChat Excel CSV Form
          worksheet.add_cell(worksheetRowPointer, 5, brsLarvicide) # 5 => Abatizado => not available in current ODK Form, but used in nicaragua
          worksheet.add_cell(worksheetRowPointer, 6, brsLarvae) # "¿Larvas?" in DengueChat Excel CSV Form
          worksheet.add_cell(worksheetRowPointer, 7, brsPupae) # "¿Pupas?" in DengueChat Excel CSV Form
          worksheet.add_cell(worksheetRowPointer, 8, brsPictureUrl) # 8 => "¿Foto de criadero?"  in DengueChat Excel CSV Form => ToDo: collected in URL form (but excel csv expects just a boolean)
          worksheet.add_cell(worksheetRowPointer, 9, brsEliminationDate) # "Fecha de eliminación (YYYY-MM-DD)" in DengueChat Excel CSV Form
          worksheet.add_cell(worksheetRowPointer, 10, brsEliminationPhoto) # 10 => "¿Foto de eliminación?" => collected in URL form (but excel csv expects just a boolean)
          worksheet.add_cell(worksheetRowPointer, 11, brsObs) # "Comentarios sobre tipo y/o eliminación" in DengueChat Excel CSV Form
          worksheet.add_cell(worksheetRowPointer, 12, brsLarvaPictureUrl) # "Foto de la Larva" NOT in DengueChat Excel CSV Form
          puts "[OdkSpreadsheetParsingWorker] Added row to workwheet: [#{vDate}|#{vAutorepFinal}|#{brsCodeFinal}|#{brsProtected}|#{brsLarvae}|#{brsPupae}|#{brsEliminationDate}|#{brsObs}]"
          persist_key_to_redis(organizationId, "inspection", "processed", inspectionFormId)
        else
          puts "[OdkSpreadsheetParsingWorker] This inspection is repeated: [#{vDate}|#{vAutorepFinal}|#{brsCodeFinal}|#{brsProtected}|#{brsLarvae}|#{brsPupae}|#{brsEliminationDate}|#{brsObs}] (#{inspectionFormId})"
          persist_key_to_redis(organizationId, "inspection", "failed:repeated", inspectionFormId)
        end
      end
    else
      # Default values if there are no inspections associated to an Efective VISIT
      brsCodeFinal = "N"
      brsLocalization = ""
      brsProtected = ""
      brsLarvicide = ""
      brsLarvae = ""
      brsPupae = ""
      brsEliminationDate = ""
      brsEliminationPhoto = ""
      brsObs = ""
      brsPictureUrl = ""
      brsLarvaPictureUrl = ""
      worksheet.add_cell(worksheetRowPointer, 2, brsCodeFinal) # 	"Tipo de criadero" in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 3, brsLocalization) # 3 => "Localización" => not available in current ODK Form
      worksheet.add_cell(worksheetRowPointer, 4, brsProtected) # "¿Protegido?" in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 5, brsLarvicide) # 5 => Abatizado => not available in current ODK Form, but used in nicaragua
      worksheet.add_cell(worksheetRowPointer, 6, brsLarvae) # "¿Larvas?" in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 7, brsPupae) # "¿Pupas?" in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 8, brsPictureUrl) # 8 => "¿Foto de criadero?"  in DengueChat Excel CSV Form => ToDo: collected in URL form (but excel csv expects just a boolean)
      worksheet.add_cell(worksheetRowPointer, 9, brsEliminationDate) # "Fecha de eliminación (YYYY-MM-DD)" in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 10, brsEliminationPhoto) # 10 => "¿Foto de eliminación?" => collected in URL form (but excel csv expects just a boolean)
      worksheet.add_cell(worksheetRowPointer, 11, brsObs) # "Comentarios sobre tipo y/o eliminación" in DengueChat Excel CSV Form
      worksheet.add_cell(worksheetRowPointer, 12, brsLarvaPictureUrl) # "Foto de la Larva" NOT in DengueChat Excel CSV Form
    end
    return worksheetRowPointer
  end

  # ToDo: in all the places we read data from a cell in the CSV, implement reading the data from the fallback columns if there was no valid data in the default
  # Todo: i.e., if the value at line.split(",")[columnOfVisitKey] is not valid, try with the next column number in the array of @@inspection_fields_dict[:iVisitFormParent]
  # ToDo: this applies to all the places where we are referring to columns in the CSV

  def self.perform
    Rails.logger.debug "[OdkSpreadsheetParsingWorker] Started the ODK synchronization worker..."

    # Read organizations grouped by the configuration parameters
    organizations = Parameter.all.group_by do |parameter| 
      parameter.organization_id
    end
    organizations.each do |id, parameters|
      organizations[id] = parameters.group_by { |parameter| parameter.key }
    end

    # Parse the data URLs for each organization.
    # Current version works only with three different CSVs, produced by an ODK collect form
    # In all cases, 4 URLs to CSVs are needed:
    # 1. A spreadsheet/csv with info about visited locations
    # 2. A spreadsheet/csv with info about each visit for each location
    # 3. A spreadsheet/csv with info about each different breeding site found in each visit
    # 4. A XMLForm specification (to use to store information that is not currently in the model of DengueChat)
    # # Run the parser only if all 4 URLs are set
    organizations.each do |organizationId, parameters|
      visitsUrl = parameters[@@parameter_keys[:visitsUrlKey]]
      locationsUrl = parameters[@@parameter_keys[:locationsUrlKey]]
      inspectionsUrl = parameters[@@parameter_keys[:inspectionsUrlKey]]
      xmlFormUrl = parameters[@@parameter_keys[:xmlFormUrlKey]]
      defaultUser = parameters[@@parameter_keys[:defaultUserKey]]

      if (!visitsUrl.nil? && !locationsUrl.nil? && !inspectionsUrl.nil?)
        # Read the XML form spec
        xmldoc = xmlFormUrl != nil ? Nokogiri::HTML(open(xmlFormUrl[0].value)) : nil
        # Read who the default user to upload this data should be
        defaultUser =  defaultUser != nil ? defaultUser[0].value : 'cdparra' # static by the moment

        # Read locations and group by location name
        locationFileContent = read_csv_and_group_by(locationsUrl[0].value,@@lNameKeys, 0)
        locationsHeader = locationFileContent[:header]
        locations = locationFileContent[:fileGroupedByKey]

        # Read visits and group by location name/ID
        visitFileContent = read_csv_and_group_by(visitsUrl[0].value,@@vParentFormIdKeys, 0)
        visitsHeader = visitFileContent[:header]
        visitsPerLocation = visitFileContent[:fileGroupedByKey]

        # Read inspections and group by visits
        inspectionFileContent = read_csv_and_group_by(inspectionsUrl[0].value,@@iVisitIdKeys, 0)
        inspectionsHeader = inspectionFileContent[:header]
        inspectionsPerVisit = inspectionFileContent[:fileGroupedByKey]

        # Read all the already proccessed location and form IDs
        locationsIds = read_all_keys_from_redis(organizationId, "location", "processed")
        visitIds = read_all_keys_from_redis(organizationId, "visit", "processed")

        total_forms = 0
        locations.each do |key, locationForms|
          count_forms = locationForms.nil? ? 0 : locationForms.length
          total_forms = total_forms + count_forms
          count_visits = 0
          count_inspections = 0
          locationName = key
          workbook = nil
          worksheet = nil
          # If location does not exist in DengueChat, do not process any of its forms
          locationEntity = Location.find_by_address(locationName)
          isLocationMissing = read_key_from_redis(organizationId, "location", "missing:name", locationName)
          if (locationEntity.nil?)
            persist_key_to_redis(organizationId, "location", "missing:name", locationName)
          else
            # If the location was marked as missing before, but it now exists, remove it from the list
            if (isLocationMissing==1)
              remove_key_from_redis(organizationId, "location","missing:name",locationName)
            end

            # Read the list of visit form IDs that were already processed before
            locationForms.each_with_index do |location, locationFormIndex|
              locationArray  = location.split(",")
              formId = extract_data_from_record(locationArray, locationsHeader, @@lFormIdKeys, 0)
              if !locationsIds.include? formId
                locationsIds.push(formId)
                visitsByForm = visitsPerLocation[formId]
                local_count = visitsByForm.nil? ? 0 : visitsByForm.length
                count_visits = count_visits+local_count
                if (local_count > 0)
                  visitStartingRow = 4
                  firstVisitToProcess = true
                  visitsByForm.each_with_index do |visit, visitIndex|
                    visitArray  = visit.split(",")
                    visitFormId = extract_data_from_record(visitArray, visitsHeader, @@vFormIdKeys, 0)

                    if !visitIds.include? visitFormId
                      visitIds.push(visitFormId)
                      inspectionsArray = inspectionsPerVisit[visitFormId]
                      count_inspections = inspectionsArray.nil? ? count_inspections+0 : count_inspections+inspectionsArray.length
                      visitStatus = extract_data_from_record(visitArray,visitsHeader, @@vStatusKeys, 0)
                      visitDate = extract_data_from_record(visitArray,visitsHeader, @@vDateKeys, 0)

                      # The following visit records will be discarded:
                      # - Visits without inspections with status C or R
                      # - Visits without inspections with status E should be registered with one inspection and breeding site "N"
                      if (visitStatus!="E")
                        # Store in REDIS visits form IDs that were not processed because they had status C or R
                        persist_key_to_redis(organizationId,"visit","failed:#{visitStatus}",visitFormId)
                        persist_key_to_redis(organizationId,"visit","failed:#{visitStatus}:date",visitDate)
                        persist_key_to_redis(organizationId,"visit","failed:#{visitStatus}:location",locationName)
                      else
                        # If we are processing the first location form and first visit, we have to
                        # start the creation of the XLS file to import
                        if locationFormIndex == 0 && firstVisitToProcess
                          puts "Starting the workbook for location #{locationName}"
                          workbook = RubyXL::Workbook.new
                          worksheet = workbook[0]
                          worksheet.add_cell(0,0,"Código o dirreción")
                          worksheet.add_cell(0,1,locationName)
                          worksheet.add_cell(1,0,"Permiso")
                          worksheet.add_cell(1,1,"1")
                          @@dengue_chat_csv_header_keys.each_with_index  do |columnTitle, index|
                            worksheet.add_cell(3, index, columnTitle) # add all the headers of the CSV in the third row
                          end
                          firstVisitToProcess = false
                        end
                        worksheetRowPointer = prepare_and_process_denguechat_csv(organizationId, xmldoc, locationArray,
                                                                                 locationsHeader, visitArray,
                                                                                 visitsHeader, visitIndex,
                                                                                 inspectionsArray, inspectionsHeader,
                                                                                 worksheet, visitStartingRow)
                        visitStartingRow = worksheetRowPointer+1
                        persist_key_to_redis(organizationId,"visit","processed",visitFormId)
                      end
                    else
                      persist_key_to_redis(organizationId,"visit","failed:repeated",visitFormId)
                    end
                  end # visitByForms.each
                end # if local_count > 0
                persist_key_to_redis(organizationId, "location", "processed", formId)
              else
                persist_key_to_redis(organizationId, "location", "failed:repeated", formId)
              end # if !locationsIds.include? formId
              puts "#{formId}: Finished Location with this form ID"
            end # locationFormsEach
          end

          # Now that all forms of these location has been processed, save and import the Excel file
          if (!workbook.nil?)
            # Temporary Excel file generated and upload it to the S3 server
            fileName=locationName
            workbook.write("#{Rails.root}/#{fileName}.xlsx")
            upload = ActionDispatch::Http::UploadedFile.new({
                                                                :filename => "#{fileName}.xlsx",
                                                                :content_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                                                :tempfile => File.new("#{Rails.root}/#{fileName}.xlsx")
                                                            })

            Rails.logger.debug "[OdkSpreadsheetParsingWorker] Temporary XLSX file: "+"#{Rails.root}/#{fileName}.xlsx"
            # ToDo: associate csv_uuid with location form id (the main ID of the ODK form)
            # ToDo: check that all the locations for Asunción exist in database
            # ToDo: Revise CSV Report code to process all data correctly
            # ToDo: Process inspection pictures if there are (extract the URL, donwload and save)
            # ToDo: Process inspection larvae pictures if there are (extract the URL, donwload and save)
            # ToDo: If a breeding site code is the same than that found in same location with same code, consider it the same br site
            # ToDo: find a way to store also the Closed or Rejected visited (for statistics purposes)
            # ToDo: integrate a CSV parsing library (to prevent issues with quoting, double-quoting, different types of separators, etc.)

            # Use the generated CSV and then re-use excel parsing to upload the data
            # ToDo: change the CsvReportsController to consider a username for each inspection in the CSV itself
            API::V0::CsvReportsController.batch(
                :csv => upload,
                :file_name => "#{fileName}.xlsx",
                :username => defaultUser,
                :organization_id => organizationId,
                :source => "ODK Form",
                :contains_photo_urls => true,
                :username_per_locations => true)
            # Delete the local file
            #File.delete("#{Rails.root}/#{fileName}.xlsx") if File.exist?("#{Rails.root}/#{fileName}.xlsx")
          end # if workbook.nil?
          puts "Finished synchronization of forms for location #{key}: proccessed #{count_forms} forms, #{count_visits} visits, and #{count_inspections} inspections."
        end # locations.each
        puts "Finished synchronization of ODK forms for organization #{organizationId}. Proccessed #{total_forms} forms."
      end
    end
    OdkSpreadsheetParsingWorker.perform_in(1.day)
  end
end

