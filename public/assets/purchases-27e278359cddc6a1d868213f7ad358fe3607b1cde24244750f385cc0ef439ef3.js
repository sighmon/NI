function sendPurchase(){ga("send","event","purchase","buy",issueNumber,issuePrice),dataLayer.push({conversionValue:issuePrice,issueNumber:issueNumber,event:"purchase"}),ga("ecommerce:addTransaction",{id:purchaseID,revenue:issuePrice,shipping:"0",tax:"0",currency:"AUD"}),ga("ecommerce:addItem",{id:purchaseID,name:issueTitle,sku:"issue"+issueNumber,category:"Single issue",price:issuePrice,currency:"AUD",quantity:"1"}),ga("ecommerce:send"),ga("ecommerce:clear")}function sendPrePurchase(e,s){ga("send","event","prePurchase","buy",e,s),dataLayer.push({conversionValue:s,issueNumber:e,event:"prePurchase"})}