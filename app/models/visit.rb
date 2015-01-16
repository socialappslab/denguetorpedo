# The Visit class is an alias class for LocationStatus (technically,
# it's a subclass of LocationStatus class).
#
# This is the correct real-world representation of LocationStatus, as
# we're tracking the health status of a location at a given time. This
# "track" can be roughly thought of as a visit to that location.
#
# Armed with this thought process, it now becomes obvious to append
# more properties to this model. For instance,
# * dengue cases,
# * chik cases,
# * identification type (positive, potential, or negative/clean)
# * time of identification
# * time of cleaning (if the elimination was performed).
#
# Note that this model limits the number of actions a user can do: either
# identify (and do nothing), or identify and clean the whole place.
class Visit < LocationStatus
end
