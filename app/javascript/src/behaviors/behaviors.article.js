jQuery.extend(Behaviors, {
  article: {
    form: {
      init: function() {
        $('.select2').each(function () { $(this).select2({ multiple: true }); });
      }
    }
  }
});
