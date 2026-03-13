function hasGoogleAnalytics() {
	return typeof ga === 'function';
}

function hasDataLayer() {
	return typeof dataLayer !== 'undefined' && dataLayer && typeof dataLayer.push === 'function';
}

function sendSubscription() {
	// console.log('Subscription price:', subscriptionPrice, ' Type:', subscriptionType, ' PurchaseID:', purchaseID, ' Number:', 'sub' + subscriptionNumber);

	// Send google the event for conversions
	if (hasGoogleAnalytics()) {
		ga('send', 'event', 'subscription', 'buy', subscriptionType, subscriptionPrice);
	}

	// Send the adwords conversion
	if (hasDataLayer()) {
		dataLayer.push({
	    'conversionValue': subscriptionPrice,
	    'subscriptionType': subscriptionType,
	    'event': 'subscription'
	  });
	}

	// Send google the ecommerce
	if (!hasGoogleAnalytics()) {
		return;
	}
	ga('ecommerce:addTransaction', {
		'id': purchaseID,
		'revenue': subscriptionPrice,
		'shipping': '0',
		'tax': '0',
		'currency': 'AUD'  					// local currency code.
	});
	ga('ecommerce:addItem', {
		'id': purchaseID,					// Transaction ID. Required.
		'name': subscriptionType,			// Product name. Required.
		'sku': 'sub' + subscriptionNumber,	// SKU/code.
		'category': 'Subscription',			// Category or variation.
		'price': subscriptionPrice,			// Unit price.
		'currency': 'AUD',
		'quantity': '1'						// Quantity.
	});
	ga('ecommerce:send');
	ga('ecommerce:clear');
	// console.log('Subscription finished.');
};

function sendPreSubscription() {
	// Send google the pre-purchase event
	if (hasGoogleAnalytics()) {
		ga('send', 'event', 'preSubscription', 'buy');
	}
	if (hasDataLayer()) {
		dataLayer.push({
	    // 'conversionValue': subscriptionPrice,
	    // 'subscriptionType': subscriptionType,
	    'event': 'preSubscription'
	  });
	}
	// console.log('PreSubscription made.');
};

jQuery(document).ready(function() {
	var container = $('[data-paypal-subscription]');
	if (container.length === 0 || typeof paypal === 'undefined') {
		return;
	}

	var option = JSON.parse(container.attr('data-option'));
	var config = container.data();
	var buttonContainer = document.getElementById('paypal-subscription-button');
	var errorContainer = container.find('[data-paypal-error]');
	window.subscriptionPrice = config.subscriptionPrice;
	window.subscriptionType = config.subscriptionType;
	window.purchaseID = config.purchaseId;
	window.subscriptionNumber = config.subscriptionNumber;

	function postJson(url, payload) {
		return $.ajax({
			url: url,
			method: 'POST',
			headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
			dataType: 'json',
			data: $.extend({}, option, payload)
		});
	}

	var buttonsConfig = {
		onApprove: function(data) {
			var finalizeUrl = option.autodebit ? config.finalizeSubscriptionUrl : config.finalizeOrderUrl;
			var payload = option.autodebit ? { paypal_subscription_id: data.subscriptionID } : { paypal_order_id: data.orderID };

			return postJson(finalizeUrl, payload).then(function(response) {
				sendSubscription();
				window.location = response.redirect_url || config.successUrl;
			}).fail(function(xhr) {
				errorContainer.text(xhr.responseJSON && xhr.responseJSON.error ? xhr.responseJSON.error : 'Could not complete this PayPal subscription.').removeClass('d-none');
			});
		},
		onError: function(err) {
			console.log(err);
			errorContainer.text('PayPal could not start this subscription. Check the browser console and network response for the PayPal request.').removeClass('d-none');
		}
	};

	if (option.autodebit) {
		buttonsConfig.createSubscription = function() {
			sendPreSubscription();
			return postJson(config.createSubscriptionUrl, {}).then(function(response) {
				return response.id;
			});
		};
	} else {
		buttonsConfig.createOrder = function() {
			sendPreSubscription();
			return postJson(config.createOrderUrl, {}).then(function(response) {
				return response.id;
			});
		};
	}

	paypal.Buttons(buttonsConfig).render(buttonContainer);
});
