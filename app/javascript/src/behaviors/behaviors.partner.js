jQuery.extend(Behaviors, {
  partner: {
    form: {
      init: function() {
        var map = [];
        
        console.log('partners sites thingy happening');

        /* service area bits */

        // Attach select2 to the current select2 nodes
        $('.select2').each(function () { $(this).select2({ multiple: false }); });

        // Attach select2 to all future select2 nodes
        $('.sites_neighbourhoods').bind('cocoon:after-insert', function (_, element) {
          $('.select2', element).select2({ multiple: false });
        });

        /* */
        
        var preview = $(".brand_image");
        
        $("#partner_image").change(function(event){
           var input = $(event.currentTarget);
           var file = input[0].files[0];
           var reader = new FileReader();
           reader.onload = function(e){
              image_base64 = e.target.result;
              preview.attr("src", image_base64);
           };
           reader.readAsDataURL(file);
        });

        $(document).on('nested:fieldAdded:places', function(e) {
          var id = 'js-map-'+e.timeStamp
          $('#js-map').attr('id',id);
          map[id] = L.map(id);
          map[id].scrollWheelZoom.disable();
        });

        $(document).on('nested:fieldAdded:calendars', function(e,h) {
          $( ".select21" ).select2();
        });

        $(document).on('click', ".add_place", function() {
          $(this).parent().find('.add_address:last').click();
        });

        $(document).on('blur', '.address_field', function(){
          var parent = $(this).parents('.place')
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
  
})
