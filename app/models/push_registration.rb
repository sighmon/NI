class PushRegistration < ActiveRecord::Base
  validates :token, uniqueness: true
end
