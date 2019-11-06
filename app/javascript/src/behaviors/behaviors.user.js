jQuery.extend(Behaviors, {
  user: {
    form: {
      init: function() {
        $( ".select2" ).select2({
          multiple: true
        });
      }
    }
  } 
});
