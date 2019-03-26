require "sidekiq"

class OdkSpreadsheetParsingWorker 
  include Sidekiq::Worker
  include OdkSpreadsheetParsing

  sidekiq_options :queue => :odk_parsing, :retry => true, :backtrace => true

  def perform # def self.perform for local testing in rails console
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
      OdkSpreadsheetParsing.perform_synchronization(organizationId,parameters)
    end
    OdkSpreadsheetParsingWorker.perform_in(7.day)
  end
end

