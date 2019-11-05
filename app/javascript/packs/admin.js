require("cocoon")
require("select2")

import 'bootstrap'

import '../src/behaviors/all_behaviors.js'

$(document).on('turbolinks:load', function() {

  $('.select-search').select2()

  $('body').init_behaviors()

  $('[data-toggle="tooltip"]').tooltip()
})
