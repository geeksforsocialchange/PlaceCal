jQuery.extend(Behaviors, {
  tag: {
    form: {
      init: function () {
        $('.select2').select2({
          multiple: true
        });
      }
    }
  }
});
