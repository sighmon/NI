class Ability
  include CanCan::Ability

  def initialize(user, key=nil)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    # can :read, Issue, :trialissue => true
    # can :index, Issue
    can [:read, :email], Issue, :published => true
    # test to see if the user has purchased an issue (to read article)
    can :read, Article, :issue => { :users => { :id => user.id } }
    # can :read, Article, :guest_passes => { :key => key } 
    can :read, Article do |article| 
        article.is_valid_guest_pass(key)
    end
    can :read, Article, :trialarticle => true
    can :search, Article
    can :read, Page
    can :read, Category

    if !user.guest?
        can :manage, Purchase
        can :manage, Subscription
        can :manage, Favourite
        can :manage, GuestPass
        can :read, User
        can :manage, User, :id => user.id
        # Ability for parents to manage children
        can :manage, User, :parent => user
        # Ability to tweet & post to facebook
        can :tweet, Article
        can :wall_post, Article
    end   

    if user.subscriber?
        can :read, :all
    end

    if user.admin?
        can :manage, :all
    end

    # Checks to see if a user has a parent, to stop institutional students from managing anything.
    if user.parent
        cannot :update, :all
        cannot :create, :all
    end

    # Institution ability
    if user.institution
        can :create, User
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
