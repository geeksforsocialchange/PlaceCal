$(document).on('turbolinks:load', function() {
  $('.js-menu').toggleClass('is-hidden');
  $('.js-menu-toggle').click(function() {
    $('.js-menu').toggleClass('is-hidden');
  })
})