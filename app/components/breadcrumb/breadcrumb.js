$(document).on('turbolinks:load', function() {
  $('.js-breadcrumb-sort :input').on('change', function() {
    $('.js-breadcrumb-sort').submit();
  });
});