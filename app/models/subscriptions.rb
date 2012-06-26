class Subscriptions < ActiveRecord::Base
  attr_accessible :expiry_date, :user_id
  belongs_to :user
end
