# -*- encoding : utf-8 -*-

class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates_presence_of :user_id, :organization_id, :role

  module Roles
    COORDINATOR = "coordenador"
    RESIDENT    = "morador"
    ADMIN       = "admin"
  end

  def coordinator?
    return self.role == Roles::COORDINATOR
  end

  def resident?
    return self.role == Roles::RESIDENT
  end

  def admin?
    return self.role == Roles::ADMIN
  end

  def manager?
    return admin? || coordinator?
  end
end
