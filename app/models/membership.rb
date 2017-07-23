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

  def options
    city = self.user.city

    n_hash = Neighborhood.order("name ASC").as_json(:only => [:id, :name])
    n_hash.map! {|n| n.merge(:code => "neighborhood", :category => I18n.t("activerecord.models.neighborhood.one") )}

    d_hash = District.order("name ASC").as_json(:only => [:id, :name])
    d_hash.map! {|n| n.merge(:code => "district", :category => I18n.t("activerecord.models.district.one") )}

    c_hash = City.order("name ASC").as_json(:only => [:id, :name])
    c_hash.map! {|n| n.merge(:code => "city", :category => I18n.t("activerecord.models.city.one") )}

    return {
      :neighborhoods => n_hash,
      :cities => c_hash,
      :districts => d_hash,
      :analytics_options => (n_hash + c_hash + d_hash)
    }
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
