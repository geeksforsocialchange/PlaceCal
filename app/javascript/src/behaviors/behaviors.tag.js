jQuery.extend(Behaviors, {
  tag: {
    form: {
      init: function() {
        $('.select2').each(function () { $(this).select2({ multiple: true }); });
      }
    }
  }
});
