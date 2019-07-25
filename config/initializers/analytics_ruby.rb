# -*- encoding : utf-8 -*-
require 'segment/analytics'

Analytics = Segment::Analytics.new(
  {
    write_key: "144181241",
    on_error: Proc.new { |status, msg| print msg }
  }
)
