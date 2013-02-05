function trackConv(google_conversion_id,google_conversion_label,google_conversion_value) {
    var image = new Image(1,1);
    console.log("Before image.src");
    image.src = "http://www.googleadservices.com/pagead/conversion/"+google_conversion_id+"/?label="+google_conversion_label+"?value="+google_conversion_value+"&script=0";
    console.log("After image.src");
} 