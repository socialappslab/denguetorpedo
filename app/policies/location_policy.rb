class LocationPolicy < Struct.new(:user, :dashboard)
  def index?
    return user.coordinator?
  end
end
