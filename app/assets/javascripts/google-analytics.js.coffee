# Put this file into your assets/javascripts/ folder and assure
# it gets loaded by checking or editing your assets/javascripts/application.js
# file as appropriate

document.addEventListener 'turbolinks:load', (event) ->
  if typeof ga is 'function'
    ga('set', 'location', event.data.url)
    ga('send', 'pageview')
