class DashboardPolicy < Struct.new(:user, :dashboard)
  def index?
    return user.coordinator?
  end

  def graphs?
    return user.coordinator?
  end

  def heatmap?
    return user.coordinator?
  end
end
