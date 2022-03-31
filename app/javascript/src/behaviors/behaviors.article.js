jQuery.extend(Behaviors, {
  article: {
    form: {
      init: function() {
        $('.select2').each(function () {
          multiple = $(this).hasClass('multi-select');
          $(this).select2({ multiple: multiple });
        });
      }
    }
  }
});
