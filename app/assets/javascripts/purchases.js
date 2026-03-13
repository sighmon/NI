// Place all the behaviors and hooks related to the matching controller here.

// jQuery(document).ready(function() {
// 	ga('require', 'ecommerce', 'ecommerce.js');
// });

function hasGoogleAnalytics() {
	return typeof ga === 'function';
}

function hasDataLayer() {
	return typeof dataLayer !== 'undefined' && dataLayer && typeof dataLayer.push === 'function';
}

function sendPurchase() {
	// Send google the event for conversions
	if (hasGoogleAnalytics()) {
		ga('send', 'event', 'purchase', 'buy', issueNumber, issuePrice);
	}

	// Send the adwords conversion
	if (hasDataLayer()) {
		dataLayer.push({
	    'conversionValue': issuePrice,
	    'issueNumber': issueNumber,
	    'event': 'purchase'
	  });
	}
	
	// Send google the ecommerce
	if (!hasGoogleAnalytics()) {
		return;
	}
	ga('ecommerce:addTransaction', {
		'id': purchaseID,
		'revenue': issuePrice,
		'shipping': '0',
		'tax': '0',
		'currency': 'AUD'  // local currency code.
	});
	// console.log('PurchaseID: ', purchaseID, 'Issue title: ', issueTitle, 'Issue number: ', 'issue' + issueNumber, 'Price: ', issuePrice);
	ga('ecommerce:addItem', {
		'id': purchaseID,				// Transaction ID. Required.
		'name': issueTitle,				// Product name. Required.
		'sku': 'issue' + issueNumber,	// SKU/code.
		'category': 'Single issue',		// Category or variation.
		'price': issuePrice,			// Unit price.
		'currency': 'AUD',
		'quantity': '1'					// Quantity.
	});
	ga('ecommerce:send');
	ga('ecommerce:clear');
	// console.log('Purchase finished.');
};

function sendPrePurchase(issueNumber, issuePrice) {
	// Send google the pre-purchase event
	if (hasGoogleAnalytics()) {
		ga('send', 'event', 'prePurchase', 'buy', issueNumber, issuePrice);
	}
	if (hasDataLayer()) {
		dataLayer.push({
	    'conversionValue': issuePrice,
	    'issueNumber': issueNumber,
	    'event': 'prePurchase'
		});
	}
	// console.log('PrePurchase made: ' + issueNumber + ', ' + issuePrice);
};

jQuery(document).ready(function() {
	var container = $('[data-paypal-issue-purchase]');
	if (container.length === 0 || typeof paypal === 'undefined') {
		return;
	}

	var config = container.data();
	var buttonContainer = document.getElementById('paypal-issue-purchase-button');
	var errorContainer = container.find('[data-paypal-error]');
	window.issueNumber = config.issueNumber;
	window.issueTitle = config.issueTitle;
	window.purchaseID = config.purchaseId;
	window.issuePrice = config.issuePrice;

	paypal.Buttons({
		createOrder: function() {
			sendPrePurchase(config.issueNumber, config.issuePrice);
			return $.ajax({
				url: config.createOrderUrl,
				method: 'POST',
				headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }
			}).then(function(response) {
				return response.id;
			});
		},
		onApprove: function(data) {
			return $.ajax({
				url: config.captureUrl,
				method: 'POST',
				headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
				dataType: 'json',
				data: {
					paypal_order_id: data.orderID
				}
			}).then(function(response) {
				sendPurchase();
				window.location = response.redirect_url || config.successUrl;
			}).fail(function(xhr) {
				errorContainer.text(xhr.responseJSON && xhr.responseJSON.error ? xhr.responseJSON.error : 'Could not complete this PayPal purchase.').removeClass('d-none');
			});
		},
		onError: function(err) {
			console.log(err);
			errorContainer.text('PayPal could not start this purchase. Check the browser console and network response for the PayPal order request.').removeClass('d-none');
		}
	}).render(buttonContainer);
});
