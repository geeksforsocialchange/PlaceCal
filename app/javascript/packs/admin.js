require("cocoon")
require("select2")

import 'bootstrap'
import 'vue'
import 'vue-turbolinks'

import '../src/behaviors/all_behaviors.js'
import '../src/opening-hours.js'

$(document).on('turbolinks:load', function() {

  $('body').init_behaviors()

  $('[data-toggle="tooltip"]').tooltip()
})
