jQuery.extend(Behaviors, {
  site: {
    form: {
      init: function() {
        // Attach select2 to all future select2 nodes
        $(".sites_neighbourhoods").bind("cocoon:after-insert", function (_, entry) {
          entry.children('.select2').first.select2({ multiple: false });
        });

        // Attach select2 to the current select2 nodes
        $( ".select2" ).select2({
          multiple: false
        });
      }
    }
  }
});
