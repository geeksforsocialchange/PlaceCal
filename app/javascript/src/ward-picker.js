import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'
import axios from 'axios'

Vue.use(TurbolinksAdapter)

// API documentation and human-readable interface
// https://geoportal.statistics.gov.uk/datasets/ward-to-local-authority-district-to-county-to-region-to-country-december-2019-lookup-in-united-kingdom

const WARD_API = "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/WD19_LAD19_CTY19_OTH_UK_LU/FeatureServer/0/query?&outFields=*&outSR=4326&f=json&where=WD19CD%20like%20"

document.addEventListener('turbolinks:load',  () => {
  var element = document.getElementById('js-ward-picker')

  if (element != null) {
    new Vue({
      el: element,
      data: {
        wardSearch: '',
        neighbourhood_name: '',
        neighbourhood_ward: '',
        neighbourhood_district: '',
        neighbourhood_county: '',
        neighbourhood_region: '',
        neighbourhood_WD19CD: '',
        neighbourhood_WD19NM: '',
        neighbourhood_LAD19CD: '',
        neighbourhood_LAD19NM: '',
        neighbourhood_CTY19CD: '',
        neighbourhood_CTY19NM: '',
        neighbourhood_RGN19CD: '',
        neighbourhood_RGN19NM: ''
      },
      methods: {
        lookupWard: function() {
          axios.get(`${WARD_API}'${this.wardSearch}'`)
            .then((response) => {
              let res = response.data.features[0].attributes
              this.neighbourhood_name = res.WD19NM
              this.neighbourhood_ward = res.WD19NM
              this.neighbourhood_district = res.LAD19NM
              this.neighbourhood_county = res.CTY19NM
              this.neighbourhood_region = res.RGN19NM
              this.neighbourhood_WD19CD = res.WD19CD
              this.neighbourhood_WD19NM = res.WD19NM
              this.neighbourhood_LAD19CD = res.LAD19CD
              this.neighbourhood_LAD19NM = res.LAD19NM
              this.neighbourhood_CTY19CD = res.CTY19CD
              this.neighbourhood_CTY19NM = res.CTY19NM
              this.neighbourhood_RGN19CD = res.RGN19CD
              this.neighbourhood_RGN19NM = res.RGN19NM
            })
        }
      }
    })
  }
})
