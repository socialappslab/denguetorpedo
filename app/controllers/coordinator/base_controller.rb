# -*- encoding : utf-8 -*-
class Coordinator::BaseController < ApplicationController
  #----------------------------------------------------------------------------

  # after_filter :verify_authorized

  #----------------------------------------------------------------------------

  before_filter :require_login
  before_filter :authorize_user

  #----------------------------------------------------------------------------

  private

  def authorize_user
    # TODO: Need to add pundit logic here.
    return true
  end

  #----------------------------------------------------------------------------

 end
