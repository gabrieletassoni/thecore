module TheCoreAbilities
  def core_abilities user
    if user
      can :access, :rails_admin # grant access to rails_admin
      can :dashboard # allow access to dashboard
      if user.admin?
        can :manage, :all # only allow admin users to access Rails Admin
        cannot :destroy, User do |u|
          # prevents killing himself
          u.id == user.id
        end
      end
    end
  end
end
