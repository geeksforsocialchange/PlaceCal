import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'
import VueTimepicker from 'vue2-timepicker/src/vue-timepicker.vue'

Vue.use(TurbolinksAdapter)
//
// opening_hours.js
//
// UI to allow the definition of a set of opening hours.
//
// The code includes a representation of the opening hours in this format:
//     https://schema.org/OpeningHoursSpecification
//
// The original version of the code was taken from https://codepen.io/mariordev/pen/RRbvgW
// Principle modifications are:
// - addition of schema.org format
// - The ability to convert between the schema.org representation and something
//   more human-readable.
// - Change of Vue major version from 1 to 2

var daysArray = [
  { value: 0, name: 'Monday', "schema.org": "http://schema.org/Monday" },
  { value: 1, name: 'Tuesday', "schema.org": "http://schema.org/Tuesday" },
  { value: 2, name: 'Wednesday', "schema.org": "http://schema.org/Wednesday" },
  { value: 3, name: 'Thursday', "schema.org": "http://schema.org/Thursday" },
  { value: 4, name: 'Friday', "schema.org": "http://schema.org/Friday" },
  { value: 5, name: 'Saturday', "schema.org": "http://schema.org/Saturday" },
  { value: 6, name: 'Sunday', "schema.org": "http://schema.org/Sunday" },
];

// Convert an added day to a schema.org OpeningHoursSpecification.
function openingHoursSpecification(day) {
  return {
    "@type": "OpeningHoursSpecification",
    closes: day.closes,
    dayOfWeek: day.dayOfWeek,
    opens: day.opens,
  }
}

// Convert a schema.org OpeningHoursSpecification to an added day.
//
function addedDay(spec) {
  return {
    dayName: daysArray.reduce( function(acc,val) {
      if (acc) {
        return acc;
      } else if (val['schema.org'] == spec.dayOfWeek){
        return val.name;
      } else {
        return false
      }
    }, false),

    openingTimeName: convertTo12Hour(spec.opens),
    closingTimeName: convertTo12Hour(spec.closes),
    // OpeningHoursSpecification:
    closes: spec.closes,
    dayOfWeek: spec.dayOfWeek,
    opens: spec.opens,
  }
}

function convertTo12Hour(time) {
  var time_arr = time.split(':');

  if(time_arr[0] === '0') {
    return '12:' + time_arr[2] + ' am';
  } else if(time_arr[0] > 12) {
    return time_arr[0] % 12 + ':' + time_arr[1] + ' pm';
  } else {
    return time_arr[0] + ':' + time_arr[1] + ' am';
  }
}

function convertTo24Hour(time) {
  if(time['a'] === 'pm') {
    if(time['hh'] === '12') {
      return '00:00:00';
    } else {
      return (parseInt(time['hh']) + 12) + ':' + time['mm'] + ':00';
    }
  } else {
    return time['hh'] + ':' + time['mm'] + ':00';
  }
}

Vue.component('added-days', {
  props: ['list'],

  template: `
    <ul class="list-unstyled">
      <li class="clearfix" v-for="day in list">
        {{ day.dayName }} from
        {{ day.openingTimeName }} to
        {{ day.closingTimeName }}

        <!-- For debugging
          {{ day.id }}
          {{ day.openingTime }}
          {{ day.closingTime }}
        -->

        <button class="btn btn-danger btn-sm pull-right" @click.prevent="removeDay(day)">Remove</button>
      </li>
    </ul>`,

  methods: {
    removeDay: function(day) {
      this.$parent.addedDays.splice(this.$parent.addedDays.indexOf(day), 1);
      this.$parent.openingHoursSpecifications =
        this.$parent.addedDays.map( openingHoursSpecification );
    },
  }
})

document.addEventListener('turbolinks:load',  () => {
  var element = document.getElementById('opening-times')
  var openingHours = JSON.parse(element.getAttribute('data'))
  if (element != null) {
    new Vue({
      el: element,

      data: {
        addedDays: openingHours.map( addedDay ),
        openingHoursSpecifications: openingHours,
        selectedDay: 0,
        selectedOpeningTime:  {
          hh: '09',
          mm: '00',
          a: 'am'
        },
        selectedClosingTime: {
          hh: '05',
          mm: '00',
          a: 'pm'
        },
        days: daysArray,
      },


      components: { VueTimepicker },

      computed: {

        selectedDayName: function() {
          return this.days[this.selectedDay].name;
        },

        selectedDaySchemaDotOrg: function() {
          return this.days[this.selectedDay]["schema.org"];
        },

        selectedOpeningTimeName: function() {
          var time = this.selectedOpeningTime
          return parseInt(time['hh']) + ':' + time['mm'] + ' ' + time['a'] ;
        },

        selectedOpeningTime24Hour: function() {
          return convertTo24Hour(this.selectedOpeningTime);
        },

        selectedClosingTimeName: function() {
          var time = this.selectedClosingTime
          return parseInt(time['hh']) + ':' + time['mm'] + ' ' + time['a'];
        },

        selectedClosingTime24Hour: function() {
          return convertTo24Hour(this.selectedClosingTime);
        }

      },

      methods: {
        addDay: function() {
          this.addedDays.push( {
            dayName: this.selectedDayName,
            openingTimeName: this.selectedOpeningTimeName,
            closingTimeName: this.selectedClosingTimeName,

            // OpeningHoursSpecification:
            closes: this.selectedClosingTime24Hour,
            dayOfWeek: this.selectedDaySchemaDotOrg,
            opens: this.selectedOpeningTime24Hour,
          } );

          this.openingHoursSpecifications =
            this.addedDays.map( openingHoursSpecification );
        },
      }
    })
  }
})
