module PaypalRest
  class PlanCatalog
    PRODUCT_SETTING_KEY = "paypal_subscription_product_id".freeze

    def initialize(client: Client.new, sandbox: PaypalConfiguration.sandbox?)
      @client = client
      @sandbox = sandbox
    end

    def ensure_plan!(option)
      setting_key = plan_setting_key(option)
      existing_plan_id = Settings.send(setting_key)

      if existing_plan_id.present?
        begin
          plan = @client.show_plan(existing_plan_id)
          activate_plan(plan)
          return plan
        rescue PaypalRest::Error
          Settings.send("#{setting_key}=", nil)
        end
      end

      product_id = ensure_product_id!
      plan = @client.create_plan(plan_payload(option, product_id))
      activate_plan(plan)
      Settings.send("#{setting_key}=", plan.fetch("id"))
      plan
    end

    private

    def ensure_product_id!
      setting_key = namespaced_setting_key(PRODUCT_SETTING_KEY)
      existing_product_id = Settings.send(setting_key)
      return existing_product_id if existing_product_id.present?

      product = @client.create_product(
        {
          name: "New Internationalist Subscriptions",
          description: "Recurring subscriptions for New Internationalist Australia.",
          type: "SERVICE",
          category: "SOFTWARE"
        }
      )
      Settings.send("#{setting_key}=", product.fetch("id"))
      product.fetch("id")
    end

    def plan_payload(option, product_id)
      {
        product_id: product_id,
        name: option.plan_name,
        description: option.description,
        status: "ACTIVE",
        billing_cycles: [
          {
            tenure_type: "REGULAR",
            sequence: 1,
            total_cycles: 0,
            frequency: {
              interval_unit: "MONTH",
              interval_count: option.duration
            },
            pricing_scheme: {
              fixed_price: {
                currency_code: "AUD",
                value: option.price_value
              }
            }
          }
        ],
        payment_preferences: {
          auto_bill_outstanding: true,
          setup_fee_failure_action: "CONTINUE",
          payment_failure_threshold: 1
        }
      }
    end

    def activate_plan(plan)
      return if plan["status"] == "ACTIVE"

      @client.activate_plan(plan.fetch("id"))
    end

    def plan_setting_key(option)
      namespaced_setting_key("paypal_subscription_plan_#{option.key}")
    end

    def namespaced_setting_key(base_key)
      @sandbox ? "sandbox_#{base_key}" : base_key
    end
  end
end
