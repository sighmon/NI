class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:login]

  # Validate username
  validates_presence_of :username
  validates_uniqueness_of :username

  # join-model for purchases
  has_many :purchases
  has_many :issues, :through => :purchases

  # association for subscriptions
  has_many :subscriptions

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
  attr_accessible :issue_ids, :login, :username, :expirydate, :admin, :subscriber, :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  #Override to_s to show user details instead of #string
  def to_s
    "#{username}"
  end

  def subscription_valid?
    return self.subscriptions.collect{|s| s.is_current?}.include?(true)
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

  def expiry_date
    # FIXME: check for cancelled subscriptions
    return self.subscriptions.collect{|s| s.expiry_date}.sort.last
  end

  def recurring_subscription
    return self.subscriptions.select{|s| s.is_recurring?}.sort!{|a,b| a.expiry_date <=> b.expiry_date}.last
  end

  def last_subscription
    return self.current_subscriptions.sort!{|a,b| a.expiry_date <=> b.expiry_date}.last
  end

  def current_subscriptions
    return self.subscriptions.select{|s| s.is_current?}
  end

  def refunds_due
    return self.subscriptions.collect{|s| s.refund or 0}.sum
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
