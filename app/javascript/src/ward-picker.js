import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'
import axios from 'axios'

Vue.use(TurbolinksAdapter)

const WARD_API = "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/WD19_LAD19_CTY19_OTH_UK_LU/FeatureServer/0/query?&outFields=*&outSR=4326&f=json&where=WD19CD%20like%20"

document.addEventListener('turbolinks:load',  () => {
  var element = document.getElementById('js-ward-picker')

  if (element != null) {
    new Vue({
      el: element,
      data: {
        ward: ''
      },
      methods: {
        lookupWard: function() {
          console.log(this.ward)
          axios.get(`${WARD_API}'${this.ward}'`)
            .then((response) => {
              console.log(response.data)
            })
        }
      }
    })
  }
})
