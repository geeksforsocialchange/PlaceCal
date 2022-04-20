/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_include_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// How to add actiocable/activestorage
//
// yarn add @rails/actioncable @rails/activestorage
// require("@rails/activestorage").start()
// require("channels")

require("@rails/ujs").start()
require("turbolinks").start()
require("leaflet")

import './src/reveal.js'

// Mountain View
export default function loadComponents(context) {
  context.keys().forEach(context);
}
loadComponents(require.context("../components", true, /\.js$/));

