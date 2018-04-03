jQuery.extend(Behaviors, {
  place: {
    form: {
      init: function() {
        var map = [];

        $( ".select2" ).select2({
          multiple: false
        });

        $(document).on('nested:fieldAdded:address', function(e) {
          $(".add_new").addClass("hide");
          $(".existing").addClass("hide");
          var id = 'js-map-'+e.timeStamp
          $('#js-map').attr('id',id);
          map[id] = L.map(id);
          map[id].scrollWheelZoom.disable();
        });

        $(document).on('click', ".add_existing", function(){
          $(".add_new").removeClass("hide");
          $(".existing").removeClass("hide");
          $(".remove_new").click();
        });

        $(document).on('blur', '.address_field', function(){
          var parent = $(this).parents('.new')
          var address_1 = $.trim(parent.find('.address_1').val());
          var address_2 = $.trim(parent.find('.address_2').val());
          var city = $.trim(parent.find('.city').val());
          var postcode = $.trim(parent.find('.postcode').val());
          var map_id = parent.find('.place-map').attr('id');
          if(address_1 != "" && city != "" && postcode != ""){
            full_address =  address_1 + "," + address_2 + "," + city + "," + postcode;
            Behaviors.map.set_address_latlng(full_address, map[map_id]);
          }
        });
      }
    }
  } 
});
