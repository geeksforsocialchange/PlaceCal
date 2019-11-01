jQuery.extend(Behaviors, {
  place: {
    form: {
      init: function() {
        var map = [];

        $( ".select2" ).select2({
          multiple: false
        });

        $(document).on('nested:fieldAdded:address', function(e) {
          var id = 'js-map-'+e.timeStamp
          $('#js-map').attr('id',id);
          map[id] = L.map(id);
          map[id].scrollWheelZoom.disable();
        });

        $(document).on('click', "li.select-existing-address > a", function(){
          $("#add-new-address").addClass("hide");
          $("#select-existing-address").removeClass("hide");
          $("li.add-new-address").removeClass("active");
          $("li.select-existing-address").addClass("active");
          $("a.exec-remove-new-address").click();
        });

        $(document).on('click', "li.add-new-address > a", function(){
          $("#add-new-address").removeClass("hide");
          $("#select-existing-address").addClass("hide");
          $("li.add-new-address").addClass("active");
          $("li.select-existing-address").removeClass("active");
          $("a.exec-add-new-address").click();
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
