module PaypalRest
  class WebhookHandler
    def initialize(event:, client: Client.new)
      @event = event
      @client = client
    end

    def process!
      notification, created = record_notification
      return notification unless created

      case event_type
      when "PAYMENT.SALE.COMPLETED"
        renew_subscription
      when "BILLING.SUBSCRIPTION.CANCELLED"
        notify_subscription_cancelled
      end

      notification
    end

    private

    def record_notification
      notification = PaymentNotification.find_or_initialize_by(
        transaction_id: event_id,
        transaction_type: event_type
      )
      created = notification.new_record?

      if created
        notification.status = event_status
        notification.user = user if user.present?
        notification.save!
      end

      [notification, created]
    end

    def renew_subscription
      return if user.blank?

      first_subscription = user.first_recurring_subscription(subscription_id)
      return if first_subscription.blank?

      Subscription.create!(
        paypal_profile_id: subscription_id,
        paypal_payer_id: first_subscription.paypal_payer_id,
        paypal_email: first_subscription.paypal_email,
        paypal_first_name: first_subscription.paypal_first_name,
        paypal_last_name: first_subscription.paypal_last_name,
        price_paid: price_paid_cents,
        user_id: user.id,
        valid_from: (user.last_subscription.try(:expiry_date) || DateTime.now),
        duration: first_subscription.duration,
        paper_copy: first_subscription.paper_copy,
        paper_only: first_subscription.paper_only,
        purchase_date: DateTime.now
      )
    end

    def notify_subscription_cancelled
      return if user.blank? || !user.subscription_valid?

      subscription = user.recurring_subscriptions(subscription_id).last
      return if subscription.blank?

      begin
        UserMailer.delay.subscription_cancelled_via_paypal(subscription)
        ApplicationHelper.start_delayed_jobs
      rescue Exception
        Rails.logger.error "500 - Email server is down..."
      end
    end

    def event_type
      @event.fetch("event_type")
    end

    def event_id
      @event["id"].presence || @event.dig("resource", "id")
    end

    def event_status
      @event.dig("resource", "status").presence || @event["summary"].presence || event_type
    end

    def subscription_id
      @subscription_id ||= @event.dig("resource", "billing_agreement_id").presence ||
        @event.dig("resource", "supplementary_data", "related_ids", "subscription_id").presence ||
        @event.dig("resource", "id").presence
    end

    def user
      @user ||= Subscription.find_by(paypal_profile_id: subscription_id).try(:user)
    end

    def price_paid_cents
      amount = @event.dig("resource", "amount", "total").presence || @event.dig("resource", "amount", "value")
      (BigDecimal(amount.to_s) * 100).to_i
    end
  end
end
