// Code removed from 'complete your purchase' button
// , :onclick => "trackConv(1072702417,'luYUCKztvAQQ0cfA_wM',#{number_with_precision((session[:express_purchase_price] / 100), :precision => 2)},'subscription');"

// Not using it, embedded in page.
/*function trackConv(google_conversion_id,google_conversion_label,google_conversion_value,purchase_type) {
    var image = new Image(1,1);
    image.src = "http://www.googleadservices.com/pagead/conversion/"+google_conversion_id+"/?label="+google_conversion_label+"?value="+google_conversion_value+"&script=0";
    _gaq.push(["_trackEvent",purchase_type,"purchase",google_conversion_label,google_conversion_value]);
} */

function sendSubscription() {
	console.log('Subscription price:', subscriptionPrice, ' Type:', subscriptionType, ' PurchaseID:', purchaseID, ' Number:', subscriptionNumber);

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

	// Send google the event for conversions
	ga('send', 'event', 'subscription', 'buy', subscriptionType, subscriptionPrice);
	console.log('Subscription finished.');
};