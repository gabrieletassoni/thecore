class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user
      can :access, :rails_admin   # grant access to rails_admin
      can :dashboard              # allow access to dashboard
      if user.admin?
        can :manage, :all       # only allow admin users to access Rails Admin
        cannot :destroy, User do |u| u.id == user.id end # prevents killing himself
        cannot [:create, :update, :destroy], PrintJob
      else # only normal users not normal users and admins
        if user.has_role? :workers
          # can :manage, Commission
          can :read, ChosenItem
          can :create, Timetable
          can :read, Timetable, user_id: user.id
          can :update, Timetable do |t| (t.user_id == user.id && t.created_at >= (Date.today - 2.days)) end
          cannot :destroy, Timetable
        end
      end
    else # GUEST
    end
  end
end
