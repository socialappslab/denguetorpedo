class MapCoordinatesWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :map_coordinates, :retry => true, :backtrace => true

  def perform(report_id)
    # An exception will be raised if this instance hasn't been persisted yet.
    report = Report.find(report_id)
  end
end
