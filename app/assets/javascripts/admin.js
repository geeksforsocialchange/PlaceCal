//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require jquery_nested_form
//= require select2
//= require leaflet
//= require ./behaviors/behaviors.base
//= require ./behaviors/behaviors.partner
//= require ./behaviors/behaviors.map

$(document).ready(function (){
  $('body').init_behaviors();
})
