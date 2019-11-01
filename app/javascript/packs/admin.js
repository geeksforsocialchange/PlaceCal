require("cocoon")
require("select2")
require("bootstrap")
require("popper")

import '../src/behaviors/behaviors.base.js'
import '../src/behaviors/behaviors.collection.js'
import '../src/behaviors/behaviors.map.js'
import '../src/behaviors/behaviors.partner.js'
import '../src/behaviors/behaviors.place.js'
import '../src/behaviors/behaviors.user.js'

$(document).on('turbolinks:load', function() {
  $(".starting-datetimepicker").datetimepicker({
    debug: false,
    format: "YYYY-MM-DD"
  });

  $(".field-unit__field.select-search select").selectize({});

  $('.select-search').select2()

  $('body').init_behaviors();
})
