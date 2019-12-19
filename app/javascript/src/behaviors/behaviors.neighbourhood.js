jQuery.extend(Behaviors, {
  neighbourhood: {
    form: {
      init: function() {
        $( ".select2" ).select2({
          multiple: true
        });
      }
    }
  }
});
