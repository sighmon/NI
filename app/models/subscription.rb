class Subscription < ActiveRecord::Base
  belongs_to :user
  attr_accessible :valid_from, :duration, :cancellation_date, :user_id, :paypal_payer_id, :paypal_email, :paypal_profile_id, :paypal_first_name, :paypal_last_name, :refund

  validates_presence_of :valid_from, :duration

 #  def recurring?
	# return (not self.paypal_profile_id.nil?)
 #  end

  def is_current?
    return (expiry_date > DateTime.now and (not is_cancelled?))
  end

  def expiry_date
    return (cancellation_date or (valid_from + duration.months))
  end

  def is_recurring?
  	 return (was_recurring? and (not is_cancelled?))
  end

  def was_recurring?
  	return (not self.paypal_profile_id.blank?)
  end

  def is_cancelled?
  	return ( not ( cancellation_date.nil? or cancellation_date > DateTime.now ))
  end

  # From controller

  def calculate_refund
    # TODO: Write autodebit renewal after we've implemented it.
    # FIXME: write the logic to calculate refunds properly.
    self.refund = [0,(1-(used_days/total_days))*self.price_paid].max.floor
    logger.warn "Refund of #{self.refund} cents due."
  end

  def used_days
    return (DateTime.now - self.valid_from.to_datetime).to_f
  end

  def total_days
    return (self.expiry_date - self.valid_from.to_datetime).to_f
  end

  def expire_subscription
    self.cancellation_date = DateTime.now
  end

end