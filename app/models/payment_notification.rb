class PaymentNotification < ActiveRecord::Base
	attr_accessor :params

	belongs_to :user, optional: true

end
