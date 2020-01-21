import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'

Vue.use(TurbolinksAdapter)

document.addEventListener('turbolinks:load',  () => {
  var element = document.getElementById('js-calendar-form')

  if (element != null) {
    new Vue({
      el: element,
      data: {
        strategy: currentInfo.strategy,
        locationVisible: true
      },
      methods: {
        updateLocation: function() {
          this.locationVisible = ['place', 'room_number', 'event_override'].includes(this.strategy)
        }
      }
    })
  }
})
