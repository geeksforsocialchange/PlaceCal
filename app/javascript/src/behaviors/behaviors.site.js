jQuery.extend(Behaviors, {
  site: {
    form: {
      init: function() {
        $( ".select2" ).select2({
          multiple: true
        });
      }
    }
  }
});
