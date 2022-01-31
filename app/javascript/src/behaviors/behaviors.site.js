jQuery.extend(Behaviors, {
  site: {
    form: {
      init: function() {
        // If the sites neighbourhood's relation_type is primary, it generates a label
        // with the class 'cocoon_delete-this'. This allows us to remove it from the form
        // so it does not submit a primary relation as being a secondary one or remove it
        $('.cocoon_delete-this').parents('.nested-fields').remove();

        // Attach select2 to the current select2 nodes
        $('.select2').each(function () { $(this).select2({ multiple: false }); });

        // Attach select2 to all future select2 nodes
        $('.sites_neighbourhoods').bind('cocoon:after-insert', function (_, element) {
          $('.select2', element).select2({ multiple: false });
        });
      }
    }
  }
});
