class LocationStatus < ActiveRecord::Base
  # The status of a location defines whether it's positive, potential, negative
  # or clean. The first three are defined by the associated reports at that
  # location, and the last one is separately set in the database. See the
  # 'status' instance method.
  module Status
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
    CLEAN     = 3
  end

  
end
