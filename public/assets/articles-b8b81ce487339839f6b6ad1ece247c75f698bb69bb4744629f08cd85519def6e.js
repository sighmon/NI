(function() {
  jQuery(function() {
    var $imageCarousel, $imageModal, dontShowAdvert, readCookie;
    $('form').on('click', '.remove_fields', function(event) {
      $(this).prev('input[type=hidden]').val('1');
      $(this).closest('fieldset').hide();
      return event.preventDefault();
    });
    $('form').on('click', '.add_fields', function(event) {
      var regexp, time;
      time = new Date().getTime();
      regexp = new RegExp($(this).data('id'), 'g');
      $(this).before($(this).data('fields').replace(regexp, time));
      $('.category_autocomplete').autocomplete({
        source: $('.autocomplete-data').data('autocomplete-source')
      });
      return event.preventDefault();
    });
    $('.category_autocomplete').autocomplete({
      source: $('.autocomplete-data').data('autocomplete-source')
    });
    readCookie = function(name) {
      var c, ca, i, nameEQ;
      nameEQ = name + '=';
      ca = document.cookie.split(';');
      i = 0;
      while (i < ca.length) {
        c = ca[i];
        while (c.charAt(0) === ' ') {
          c = c.substring(1, c.length);
        }
        if (c.indexOf(nameEQ) === 0) {
          return c.substring(nameEQ.length, c.length);
        }
        i++;
      }
      return null;
    };
    dontShowAdvert = readCookie("subscriptionAdvertClosed");
    if (dontShowAdvert !== "true") {
      $('.subscription-advert').show();
    }
    $('.subscription-advert .fa-times').click(function() {
      $('.subscription-advert').hide();
      document.cookie = "subscriptionAdvertClosed=true";
      return event.preventDefault();
    });
    $imageModal = $("#imageModal").modal({
      show: false
    });
    $imageCarousel = $("#imageCarousel").carousel({
      interval: false
    });
    $(".article-image-carousel").click(function() {
      return $imageCarousel.carousel($(this).data("slide-index"));
    });
    $('.article-body').highlighter({
      selector: ".holder",
      complete: function(data) {
        var tb;
        tb = $(".tweet-button a")[0];
        tb.href = URI(tb.href).setQuery("text", data);
        tb = $(".facebook-button a")[0];
        return tb.href = URI(tb.href).setQuery("text", data);
      }
    });
    $('.holder').mousedown(function() {
      return false;
    });
    return $('.btn-right').click(function() {
      $('.holder').hide();
      return false;
    });
  });

}).call(this);
