class Ability
  include CanCan::Ability

  def initialize(user, key=nil)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    # can :read, Issue, :trialissue => true
    # can :index, Issue
    can [:read, :email, :email_non_subscribers, :email_others, :email_renew], Issue, :published => true
    can [:tweet_issue, :wall_post_issue, :email_issue], Issue
    # test to see if the user has purchased an issue (to read article)
    can :read, Article, :issue => { :users => { :id => user.id } }
    # can :read, Article, :guest_passes => { :key => key } 
    can :read, Article do |article| 
        article.is_valid_guest_pass(key)
    end
    can :read, Article, :trialarticle => true
    can :read, Article, :issue => { :trialissue => true }
    can :search, Article
    can :popular, Article
    can :read, Page
    can :read, Category
    cannot :update_categories_colours, Category

    if !user.guest?
        can :manage, Purchase
        can :manage, Subscription
        can :manage, Favourite
        can :manage, GuestPass
        can :manage, User, :id => user.id
        cannot :manage, User do |user|
            not user.uk_id.nil?
        end
        can :read, User
        # Ability for parents to manage children
        can :manage, User, :parent => user
        # Ability to tweet & post to facebook
        can :tweet, Article
        can :wall_post, Article
        can :email_article, Article
    end   

    if user.subscriber?
        can :read, :all
        # Let subscribers who stumble upon unpublished issues/articles read them? Uncomment to dissallow
        # cannot :read, Issue, :published => false
        # cannot :read, Article, :published => false
    end

    if user.admin?
        can :manage, :all
    end

    # Checks to see if a user has a parent, to stop institutional students from managing anything.
    if user.parent
        cannot :update, :all
        cannot :create, :all
        cannot :destroy, :all
        can :create, GuestPass
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
