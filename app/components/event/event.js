$(document).on('turbolinks:load', function() {
  $('.js-pagination-sort :input').on('change', function() {
    $('.js-pagination-sort').submit();
  });
});