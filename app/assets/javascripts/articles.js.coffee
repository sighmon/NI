# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('form').on 'click', '.remove_fields', (event) ->
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('fieldset').hide()
    event.preventDefault()

  $('form').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    $('.category_autocomplete').autocomplete
      source: $('.autocomplete-data').data('autocomplete-source')
    event.preventDefault()

  $('.category_autocomplete').autocomplete
    source: $('.autocomplete-data').data('autocomplete-source')

  # Modal & Carousel setup

  $imageModal = $("#imageModal").modal(show: false)
  $imageCarousel = $("#imageCarousel").carousel(interval: false)
  $(".article-image-carousel").click ->
    $imageCarousel.carousel $(this).data("slide-index")

  # Modal size adjustments

  updateModalMargin = () -> $(".modal").css({"margin-left": -($(".modal").width() / 2)})
  updateModalHeight = () -> $(".modal-body").css({"max-height": (window.innerHeight * 0.9)})
  removeModalMargin = () -> $(".modal").css({"margin-left": "0px"})

  if (window.innerWidth > 768)
    updateModalMargin()
  updateModalHeight()

  $(window).resize ->
    if (window.innerWidth > 768)
      updateModalMargin()
    else
      removeModalMargin()
    updateModalHeight()

  $('#imageCarousel').on 'slid', (event) ->
    if (window.innerWidth > 768)
      updateModalMargin()
    else
      removeModalMargin()
    updateModalHeight()