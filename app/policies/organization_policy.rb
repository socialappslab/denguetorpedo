class OrganizationPolicy
  attr_reader :resource, :record

  def initialize(resource, record)
    @resource = resource
    @record   = record
  end

  def settings?
    return resource.manager?
  end

  def update?
    return resource.admin?
  end

  def users?
    return resource.manager?
  end

  def teams?
    return resource.manager?
  end

  def membership?
    return resource.manager?
  end
end
