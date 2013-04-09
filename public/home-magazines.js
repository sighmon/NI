$(document).ready(function() {
  var newintAPI = "http://digital.newint.com.au/issues.json";
  $.getJSON( newintAPI ).done(function( data ) {
  	// Big latest issue magazine cover
    $('.magazine-cover').html('<a href="http://digital.newint.com.au/issues/' + data[0].id + '"><img src="' + data[0].cover.thumb2x.url + '" alt="The latest edition of New Internationalist magazine" title="The latest edition of New Internationalist magazine" width="200" /></a>');
    // Loop through next 5 magazines
    for (var i = 1; i < 6; i++) {
      $('<div class="issue"><a href="http://digital.newint.com.au/issues/' + data[i].id + '"><img src="' + data[i].cover.tiny.url + '" alt="'+ data[i].title +'" title="'+ data[i].title +'" /></a><a href="http://digital.newint.com.au/issues/' + data[i].id + '"><h4>'+ data[i].title +'</h4></a><p>'+ $.strftime("%B %Y", (new Date(Date.parse(data[i].release)))) +'</p></div>').appendTo(".issue-list");
    };
  });
});