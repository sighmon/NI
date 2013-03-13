class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:login]

  # Validate username
  validates_presence_of :username
  validates_uniqueness_of :username

  # How to validate the format of username (not used)
  # validates_format_of :username, :with => /^[-_a-z0-9]+$/, :message => "Your username can only include lower case letters and numbers."

  # join-model for purchases
  has_many :purchases
  has_many :issues, :through => :purchases

  has_many :guest_passes, :dependent => :destroy
  has_many :articles, :through => :guest_passes

  # join-model for favourites
  has_many :favourites, :dependent => :destroy
  has_many :articles, :through => :favourites

  # association for subscriptions
  has_many :subscriptions

  # parent-child relationships for institutional accounts
  belongs_to :parent, :class_name => 'User', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'User', :foreign_key => 'parent_id'

  # Send a welcome email after a user is created
  after_create :send_welcome_mail

  def send_welcome_mail
    UserMailer.user_signup_confirmation(self).deliver
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :issue_ids, :login, :username, :expirydate, :subscriber, :email, :password, :password_confirmation, :remember_me
  # removed :admin so that public can't make themselves an admin
  # attr_accessible :title, :body

  # CSV exporting
  comma do

    id
    email
    expiry_date 'expiry_date'
    is_recurring? 'is_recurring'
    has_paper_copy? 'has_paper_copy'

    last_subscription_including_cancelled :paypal_first_name => 'paypal_first_name'
    last_subscription_including_cancelled :paypal_last_name => 'paypal_last_name'
    last_subscription_including_cancelled :paypal_email => 'paypal_email'
    last_subscription_including_cancelled :paper_copy => 'paper_copy'
    last_subscription_including_cancelled :purchase_date => 'purchase_date'
    last_subscription_including_cancelled :valid_from => 'valid_from'
    last_subscription_including_cancelled :duration
    last_subscription_including_cancelled :cancellation_date => 'cancellation_date'
    last_subscription_including_cancelled :paypal_country_code => 'paypal_country_code'
    last_subscription_including_cancelled :paypal_country_name => 'paypal_country_name'

  end

  #Override to_s to show user details instead of #string
  def to_s
    "#{username}"
  end

  def subscription_valid?
    if self.parent
      host = self.parent
    else
      host = self
    end
    return host.subscriptions.collect{|s| s.is_current?}.include?(true)
  end

  def subscription_lapsed?
    return ( not self.subscriptions.empty? and not self.subscription_valid? )
  end

  def subscriber?
    return subscription_valid?
  end

  def is_recurring?
    # TODO: need to differentiate between the first recurring subscription and the paypal IPN recurrances.
    return self.subscriptions.collect{|s| s.is_recurring?}.include?(true)
  end

  def has_paper_copy?
    return self.current_subscriptions.collect{|s| s.paper_copy}.include?(true)
  end

  def expiry_date
    # FIXME: check for cancelled subscriptions
    return self.subscriptions.collect{|s| s.expiry_date}.sort.last
  end

  def recurring_subscription
    return self.subscriptions.select{|s| s.is_recurring?}.sort!{|a,b| a.expiry_date <=> b.expiry_date}.last
  end

  def first_recurring_subscription(profile)
    return self.subscriptions.select{|s| (s.paypal_profile_id == profile)}.sort!{|a,b| a.purchase_date <=> b.purchase_date}.first
  end

  def recurring_subscriptions(recurring_payment_id)
    # Return all the subscriptions that have this paypal profile id
    return self.subscriptions.select{|s| (s.paypal_profile_id == recurring_payment_id)}.sort!{|a,b| a.purchase_date <=> b.purchase_date}
  end

  def last_subscription
    return self.current_subscriptions.sort!{|a,b| a.expiry_date <=> b.expiry_date}.last
  end

  def last_subscription_including_cancelled
    return self.subscriptions.sort!{|a,b| a.expiry_date_excluding_cancelled <=> b.expiry_date_excluding_cancelled}.last
  end

  def current_subscription
    return self.current_subscriptions.sort!{|a,b| a.expiry_date <=> b.expiry_date}.last
  end

  def current_subscriptions
    return self.subscriptions.select{|s| s.is_current?}
  end

  def refunds_due
    refund = self.subscriptions.collect{|s| 
      if s.refunded_on
        next 0
      else
        next (s.refund or 0)
      end
    }
    return refund.sum
  end

  def user_type
    t = "Guest"
    if admin?
      t = "Admin"
    elsif subscriber?
      t = "Subscriber"
    end
    "#{t}"
  end

  def guest?
    return id.nil?
  end

end
