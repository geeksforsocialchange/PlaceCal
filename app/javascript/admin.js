require("@rails/ujs").start()
import "@hotwired/turbo-rails"

import "bootstrap"
import "./src/jquery"

// Input selectors
require("@nathanvda/cocoon")
require("select2")(window, $)

// Datatables
import "./src/datatable.js"

// Opening times stuff
import  Vue from "vue"
import "vue-turbolinks"

// Specific pages
import "./src/calendar-form.js"
import "./src/ward-picker.js"

$(document).on("turbo:load", function () {
  $("[data-toggle='tooltip']").tooltip()
});

import "./controllers"
