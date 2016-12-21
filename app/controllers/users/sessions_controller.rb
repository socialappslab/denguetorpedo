class Users::SessionsController < Devise::SessionsController

  def new
    super
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!({ :scope => resource_name, :recall => "#{controller_path}#new" })
    res = sign_in(resource_name, resource)

    respond_with resource, :location => after_sign_in_path_for(resource)
  end

  #-------------------------------------------------------------------------------------------------

  protected

  def after_sign_in_path_for(resource_or_scope)
    return city_path(resource_or_scope.city)
  end

  #-------------------------------------------------------------------------------------------------
end
