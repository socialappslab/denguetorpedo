class CsvReportPolicy < Struct.new(:user, :dashboard)
  def index?
    return user.coordinator?
  end

  def new?
    return user.coordinator?
  end
end
