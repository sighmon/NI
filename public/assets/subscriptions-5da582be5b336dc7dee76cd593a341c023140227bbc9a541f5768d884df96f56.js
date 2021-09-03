function sendSubscription() {
	// console.log('Subscription price:', subscriptionPrice, ' Type:', subscriptionType, ' PurchaseID:', purchaseID, ' Number:', 'sub' + subscriptionNumber);

	// Send google the event for conversions
	ga('send', 'event', 'subscription', 'buy', subscriptionType, subscriptionPrice);

	// Send the adwords conversion
	dataLayer.push({
    'conversionValue': subscriptionPrice,
    'subscriptionType': subscriptionType,
    'event': 'subscription'
  });

	// Send google the ecommerce
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
	ga('send', 'event', 'preSubscription', 'buy');
	dataLayer.push({
    // 'conversionValue': subscriptionPrice,
    // 'subscriptionType': subscriptionType,
    'event': 'preSubscription'
  });
	// console.log('PreSubscription made.');
};
