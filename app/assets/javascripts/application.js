// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.ui.all
//= require jquery_ujs
//= require jquery-fileupload/basic
//= require jquery-fileupload/vendor/tmpl
//= require twitter/bootstrap
//= require_tree .
//= require retina_image_tag
//= require highlighter/jQuery.highlighter
//= require URI

var flip = 0;

jQuery(document).ready(function() {

	// Tooltips for Magazine list page
    $(".issue-cover-list img").tooltip();

    // Toggle to show/hide divs .div-to-flip using .flip-button
    $(".flip-button").click(function() {
		$(".div-to-flip").fadeToggle( flip++ % 2 == 0 );
	});
	
	// Article's top image height = 1/3 of its width
	$(window).ready(updateHeight);
	$(window).resize(updateHeight);

	function updateHeight()
	{
		var articleImageDiv = $('.article-image-top');
		var articleImageWidth = articleImageDiv.width() / 2;
	
		articleImageDiv.css('height', articleImageWidth);
	}
	
	// To fix touch dropdown menu issues
	/* https://github.com/twitter/bootstrap/issues/2975#issuecomment-6659992 */
	$('body').on('touchstart.dropdown', '.dropdown-menu', function (e) { e.stopPropagation(); });

});



