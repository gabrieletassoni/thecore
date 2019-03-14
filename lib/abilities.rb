module TheCoreAbilities
  def core_abilities(user)
    # So the static link navigation can be set runtime (yes it's an hack)
    RailsAdmin.config do |config|
      config.navigation_static_label = I18n.t('admin.links.label')
    end
    # Normal core abilities file
    if user
      can :access, :rails_admin # grant access to rails_admin
      can :dashboard, :all # allow access to dashboard
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
