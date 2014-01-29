// Place all the behaviors and hooks related to the matching controller here.

// jQuery(document).ready(function() {
// 	ga('require', 'ecommerce', 'ecommerce.js');
// });

function sendPurchase() {
	// Send google the event for conversions
	ga('send', 'event', 'purchase', 'buy', issueNumber, issuePrice);
	
	// Send google the ecommerce
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