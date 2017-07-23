class DashboardPolicy
  attr_reader :membership, :record

  def initialize(membership, record)
    @membership = membership
    @record = record
  end

  def index?
    return false if @membership.blank?
    return @membership.manager?
  end
end
