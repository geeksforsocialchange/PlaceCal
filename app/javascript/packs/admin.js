require("@nathanvda/cocoon")
require("select2")
require("datatables.net-bs4")

import 'bootstrap'
import 'vue'
import 'vue-turbolinks'

import '../src/behaviors/all_behaviors.js'
import '../src/calendar-form.js'
import '../src/datatable.js'
import '../src/opening-times.js'
import '../src/ward-picker.js'


$(document).on('turbolinks:load', function () {

  $('body').init_behaviors()

  $('[data-toggle="tooltip"]').tooltip()
});
