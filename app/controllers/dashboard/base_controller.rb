# -*- encoding : utf-8 -*-
class Dashboard::BaseController < ApplicationController
  layout "layouts/dashboard"

  #----------------------------------------------------------------------------

  before_filter :require_login
  before_filter :authorize_user
  before_filter :set_navigational_components

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def authorize_user
    # TODO: Need to add pundit logic here.
    return true
  end

  def set_navigational_components
    @navigation            ||= {}
    @navigation["parent"]  ||= {}
    @navigation["child"]   ||= {}
    @navigation["current"] ||= {}
  end

  #----------------------------------------------------------------------------

 end
