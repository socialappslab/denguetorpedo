require "sidekiq"

class CsvParsingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :csv_parsing, :retry => true, :backtrace => true

  def perform
  end
end
