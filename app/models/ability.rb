class Ability
  include CanCan::Ability

  def initialize(user, key=nil)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    # can :read, Issue, :trialissue => true
    # can :index, Issue
    can [:read, :email, :email_non_subscribers, :email_others, :email_renew, :email_special], Issue, :published => true
    can [:tweet_issue, :wall_post_issue, :email_issue], Issue
    # test to see if the user has purchased an issue (to read article)
    can :read, Article, :issue => { :id => user.issue_ids }
    # can :read, Article, :guest_passes => { :key => key } 
    can :read, Article do |article| 
        article.is_valid_guest_pass(key)
    end
    can :read, Article, :trialarticle => true
    can :read, Article, :issue => { :trialissue => true }
    # mark all letters, blogs and web-exclusives as free to read
    can :read, Article do |article|
        article.has_category("/columns/letters/") or article.has_category("/blog/") or article.has_category("/features/web-exclusive/")
    end
    can :search, Article
    can :popular, Article
    can :quick_reads, Article
    can :read, Page
    can :read, Category
    cannot :update_categories_colours, Category
    cannot :manage, PushRegistration

    if !user.guest?
        can [:create, :new], Purchase
        can :manage, Purchase, :id => user.purchase_ids
        can [:create, :new], Subscription
        can :manage, Subscription, :id => user.subscription_ids
        can [:create, :new], Favourite
        can :manage, Favourite, :id => user.favourite_ids
        can [:create, :new], GuestPass
        can :manage, GuestPass, :id => user.guest_pass_ids
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

    cannot :read, Article, :published => false
    cannot :show, Purchase do |purchase|
        not purchase.user == user
    end
    cannot :show, Subscription do |subscription|
        not subscription.user == user
    end

    if user.manager
        can :manage, User
        can :manage, Subscription
        can :show, Purchase
        can :read, Article
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
