# -*- encoding : utf-8 -*-
class Ability
  include CanCan::Ability

  def initialize(user)
    if user.coordinator?
      can(:assign_roles, User)
      can(:edit, User)
    end
  end

end
