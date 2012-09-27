class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    # can :read, Issue, :trialissue => true
    # can :index, Issue
    can :read, Issue
    can :read, Article, :trialarticle => true
    can :search, Article
    # test to see if the user has purchased an issue (to read article)
    can :read, Article, :issue => { :users => { :id => user.id } }

    if !user.guest?
        can :manage, Purchase
        can :manage, Subscription
        can :read, User
    end   

    if user.subscriber?
        can :read, :all
    end

    if user.admin?
        can :manage, :all
    end

    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
