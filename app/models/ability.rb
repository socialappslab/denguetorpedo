class Ability
  include CanCan::Ability

  def initialize(user)
    if [User::Types::ADMIN, User::Types::COORDINATOR].include?(user.role)
      can(:assign_roles, User)
      can(:edit, User)
    end
  end

end
