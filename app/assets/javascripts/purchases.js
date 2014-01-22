// Place all the behaviors and hooks related to the matching controller here.

jQuery(document).ready(function() {
	ga('require', 'ecommerce', 'ecommerce.js');
});

function sendPurchase() {
	// Send google the ecommerce
	ga('ecommerce:addTransaction', {
		'id': purchaseID,
		'revenue': issuePrice,
		'shipping': '0',
		'tax': '0',
		'currency': 'AUD'  // local currency code.
	});
	console.log(purchaseID,issueTitle, issueNumber, issuePrice);
	ga('ecommerce:addItem', {
		'id': purchaseID,				// Transaction ID. Required.
		'name': issueTitle,				// Product name. Required.
		'sku': issueNumber,				// SKU/code.
		'category': 'Single issue',		// Category or variation.
		'price': issuePrice,			// Unit price.
		'currency': 'AUD',
		'quantity': '1'					// Quantity.
	});
	ga('ecommerce:send');
	ga('ecommerce:clear');
	// Send google the event for conversions
	ga('send', 'event', 'purchase', 'buy', issueNumber, issuePrice);
	console.log('Purchase finished.');
};