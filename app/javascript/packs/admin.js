require("cocoon")
require("select2")

import 'bootstrap'

import '../src/behaviors/all_behaviors.js'

$(document).on('turbolinks:load', function() {
  $(".starting-datetimepicker").datetimepicker({
    debug: false,
    format: "YYYY-MM-DD"
  });

  $(".field-unit__field.select-search select").selectize({})

  $('.select-search').select2()

  $('body').init_behaviors()

  $('[data-toggle="tooltip"]').tooltip()
})
