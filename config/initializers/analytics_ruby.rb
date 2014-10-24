require 'segment/analytics'

Analytics = Segment::Analytics.new(
  {
    write_key: "z6gNRpVs1D",
    on_error: Proc.new { |status, msg| print msg }
  }
)
