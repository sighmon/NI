class Subscription < ActiveRecord::Base
  belongs_to :user
  attr_accessible :expiry_date, :user_id
end
