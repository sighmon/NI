function sendSubscription() {
	console.log('Subscription price:', subscriptionPrice, ' Type:', subscriptionType, ' PurchaseID:', purchaseID, ' Number:', subscriptionNumber);

	// Send google the event for conversions
	ga('send', 'event', 'subscription', 'buy', subscriptionType, subscriptionPrice);

	// Send google the ecommerce
	ga('ecommerce:addTransaction', {
		'id': purchaseID,
		'revenue': subscriptionPrice,
		'shipping': '0',
		'tax': '0',
		'currency': 'AUD'  				// local currency code.
	});
	ga('ecommerce:addItem', {
		'id': purchaseID,				// Transaction ID. Required.
		'name': subscriptionType,		// Product name. Required.
		'sku': subscriptionNumber,		// SKU/code.
		'category': 'Subscription',		// Category or variation.
		'price': subscriptionPrice,		// Unit price.
		'currency': 'AUD',
		'quantity': '1'					// Quantity.
	});
	ga('ecommerce:send');
	ga('ecommerce:clear');
	console.log('Subscription finished.');
};