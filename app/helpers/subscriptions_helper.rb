module SubscriptionsHelper	

    def subscription_price_table
    	content_tag :table, :class => 'table table-bordered subscription-price-table' do
    		content_tag :thead do
    			content_tag(:tr,
    				content_tag(:th, " ") +
    				content_tag(:th, "3 months") +
    				content_tag(:th, "6 months") +
    				content_tag(:th, "12 months")
    			) +
    			content_tag(:tr,
    				content_tag(:td, "Once-up") +
    				content_tag(:td, "$" + number_with_precision((Subscription.calculate_subscription_price(3,autodebit: false) / 100), :precision => 2)) +
    				content_tag(:td, "$" + number_with_precision((Subscription.calculate_subscription_price(6,autodebit: false) / 100), :precision => 2)) +
    				content_tag(:td, "$" + number_with_precision((Subscription.calculate_subscription_price(12,autodebit: false) / 100), :precision => 2))
    			) +
    			content_tag(:tr,
    				content_tag(:td, "Ongoing Auto-debit") +
    				content_tag(:td, "$" + number_with_precision((Subscription.calculate_subscription_price(3,autodebit: true) / 100), :precision => 2)) +
    				content_tag(:td, "$" + number_with_precision((Subscription.calculate_subscription_price(6,autodebit: true) / 100), :precision => 2)) +
    				content_tag(:td, "$" + number_with_precision((Subscription.calculate_subscription_price(12,autodebit: true) / 100), :precision => 2))
    			)
    		end
    	end
    end

end
