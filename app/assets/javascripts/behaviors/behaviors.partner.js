jQuery.extend(Behaviors, {
  partner: {
    form: {
      init: function() {
        $( ".select2" ).select2({
          multiple: true
        });

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

        $(document).on('nested:fieldAdded:calendars', function(e,h) {
          $( ".select21" ).select2();
        });

        $(document).on('click', ".add_place", function() {
          $(this).parent().find('.add_address:last').click();
        });
      }
    }
  }
  
})
