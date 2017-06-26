# -*- encoding : utf-8 -*-

class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  module Roles
    COORDINATOR = "coordenador"
    RESIDENT    = "morador"
    ADMIN       = "admin"
  end
end
