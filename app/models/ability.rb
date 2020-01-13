class Ability
  include CanCan::Ability

  include TheCoreAbilities

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

    # TODO: Spiegare meglio Taris
    # Modo per poter caricare diversi file ability presenti in diversi engine
    # bisogna creare nella cartella config/initializers dell'engine un file che
    # faccia il module_eval di TheCore::Abilities, aggiungendo un metodo
    # che accetta user come parametro e con dentro la definizione delle ability
    # include TheCore::Abilities
    core_abilities user
    TheCoreAbilities.instance_methods(false).each do |a|
      # method(a).call(user)
      # eval("#{a} #{user}")
      
      # Rails.logger.debug "LOADING ABILITIES FROM: #{a}"
      send(a, user) if a.to_s != "core_abilities"
    end
    # core_abilities user
  end
end
