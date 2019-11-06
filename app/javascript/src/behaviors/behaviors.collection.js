jQuery.extend(Behaviors, {
  collection: {
    form: {
      init: function() {
        $( ".select2" ).select2({
          multiple: true
        });
      }
    }
  }
});
