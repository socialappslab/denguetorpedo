# -*- encoding : utf-8 -*-
class Coordinator::BaseController < ApplicationController
  #----------------------------------------------------------------------------

  # after_filter :verify_authorized

  #----------------------------------------------------------------------------

  before_filter :require_login
  before_filter :authorize_user
  before_filter :update_breadcrumbs

  #----------------------------------------------------------------------------

  private

  def authorize_user
    # TODO: Need to add pundit logic here.
    return true
  end

  def update_breadcrumbs
    @breadcrumbs << {:name => I18n.t("views.coordinator.home"), :path => coordinator_path}
  end

 end
