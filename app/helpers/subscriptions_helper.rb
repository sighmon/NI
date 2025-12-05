module SubscriptionsHelper	

    def subscription_price_table
    	content_tag :table, class: 'table table-striped subscription-price-table' do
    		content_tag(:thead,
    			content_tag(:tr,
    				content_tag(:th, "Subscription options") +
    				content_tag(:th, "3 months") +
    				content_tag(:th, "6 months") +
    				content_tag(:th, "12 months")
    			)
            ) +
            content_tag(:tbody,
                content_tag(:tr,
                    content_tag(:td, "Ongoing Automatic debit digital subscription") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,autodebit: true))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,autodebit: true))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,autodebit: true)))
                ) +
    			content_tag(:tr,
    				content_tag(:td, "Once-off digital subscription") +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,autodebit: false))) +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,autodebit: false))) +
    				content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,autodebit: false)))
    			) +
                content_tag(:tr,
                    content_tag(:td, "Ongoing Automatic debit subscription, Digital + Paper") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,{autodebit: true, paper: true}))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,{autodebit: true, paper: true}))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: true, paper: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Once-off subscription, Digital + Paper") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,{autodebit: false, paper: true}))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,{autodebit: false, paper: true}))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: false, paper: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Paper only subscription") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(3,{autodebit: false, paper: true, paper_only: true}))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(6,{autodebit: false, paper: true, paper_only: true}))) +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: false, paper: true, paper_only: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Institution subscription payment, Paper only") +
                    content_tag(:td, "-") +
                    content_tag(:td, "-") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: false, paper: true, paper_only: true, institution: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Institution automatic debit subscription payment, Digital only") +
                    content_tag(:td, "-") +
                    content_tag(:td, "-") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: true, institution: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Institution automatic debit subscription payment, Digital + Paper") +
                    content_tag(:td, "-") +
                    content_tag(:td, "-") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: true, paper: true, institution: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Institution once-off subscription payment, Digital only") +
                    content_tag(:td, "-") +
                    content_tag(:td, "-") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: false, institution: true})))
                ) +
                content_tag(:tr,
                    content_tag(:td, "Institution once-off subscription payment, Digital + Paper") +
                    content_tag(:td, "-") +
                    content_tag(:td, "-") +
                    content_tag(:td, "$" + cents_to_dollars(Subscription.calculate_subscription_price(12,{autodebit: false, paper: true, institution: true})))
                )
    		)
    	end
    end

end
