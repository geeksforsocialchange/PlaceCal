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

var timesArray = [
  { value: 0, name: '12 am (midnight)', '24hour': '00:00:00' },
  { value: 1, name: '1:00 am', '24hour': '01:00:00' },
  { value: 2, name: '2:00 am', '24hour': '02:00:00' },
  { value: 3, name: '3:00 am', '24hour': '03:00:00' },
  { value: 4, name: '4:00 am', '24hour': '04:00:00' },
  { value: 5, name: '5:00 am', '24hour': '05:00:00' },
  { value: 6, name: '6:00 am', '24hour': '06:00:00' },
  { value: 7, name: '7:00 am', '24hour': '07:00:00' },
  { value: 8, name: '8:00 am', '24hour': '08:00:00' },
  { value: 9, name: '9:00 am', '24hour': '09:00:00' },
  { value: 10, name: '10:00 am', '24hour': '10:00:00' },
  { value: 11, name: '11:00 am', '24hour': '11:00:00' },
  { value: 12, name: '12:00 pm (noon)', '24hour': '12:00:00' },
  { value: 13, name: '1:00 pm', '24hour': '13:00:00' },
  { value: 14, name: '2:00 pm', '24hour': '14:00:00' },
  { value: 15, name: '3:00 pm', '24hour': '15:00:00' },
  { value: 16, name: '4:00 pm', '24hour': '16:00:00' },
  { value: 17, name: '5:00 pm', '24hour': '17:00:00' },
  { value: 18, name: '6:00 pm', '24hour': '18:00:00' },
  { value: 19, name: '7:00 pm', '24hour': '19:00:00' },
  { value: 20, name: '8:00 pm', '24hour': '20:00:00' },
  { value: 21, name: '9:00 pm', '24hour': '21:00:00' },
  { value: 22, name: '10:00 pm', '24hour': '22:00:00' },
  { value: 23, name: '11:00 pm', '24hour': '23:00:00' },
  { value: 24, name: '12:00 am (midnight next day)', '24hour': '00:00:00' },
  { value: 25, name: '1:00 am (next day)', '24hour': '01:00:00' },
  { value: 26, name: '2:00 am (next day)', '24hour': '02:00:00' },
  { value: 27, name: '3:00 am (next day)', '24hour': '03:00:00' },
  { value: 28, name: '4:00 am (next day)', '24hour': '04:00:00' },
  { value: 29, name: '5:00 am (next day)', '24hour': '05:00:00' },
  { value: 30, name: '6:00 am (next day)', '24hour': '06:00:00' },
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
// ?TODO?  Convert this function to use Array find() rather than reduce() ?
//      ?  It would be a lot more compact, but I'm not sure whether I should
//      ?  include EcmaScript 6 functions.
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
    openingTimeName: timesArray.reduce( function(acc,val) {
      if (acc) {
        return acc;
      } else if (val['24hour'] == spec.opens){
        return val.name;
      } else {
        return false
      }
    }, false),
    closingTimeName: timesArray.reduce( function(acc,val) {
      if (acc) {
        return acc;
      } else if (val['24hour'] == spec.closes){
        return val.name;
      } else {
        return false
      }
    }, false),

    // OpeningHoursSpecification:
    closes: spec.closes,
    dayOfWeek: spec.dayOfWeek,
    opens: spec.opens,
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

new Vue({
  el: '#opening-times',

  data: {
    addedDays: openingHoursFromServer.map( addedDay ),
    openingHoursSpecifications: openingHoursFromServer,
    selectedDay: 0,
    selectedOpeningTime: 9,
    selectedClosingTime: 17,
    days: daysArray,
    openingTimes: timesArray,
    closingTimes: timesArray,
  },

  computed: {

    filteredOpeningTimes: function() {
      return this.openingTimes.filter(function (el) {
        return el.value < this.selectedClosingTime;
      }, this);
    },

    filteredClosingTimes: function() {
      return this.closingTimes.filter(function (el) {
        return el.value > this.selectedOpeningTime;
      }, this);
    },

    selectedDayName: function() {
      return this.days[this.selectedDay].name;
    },

    selectedDaySchemaDotOrg: function() {
      return this.days[this.selectedDay]["schema.org"];
    },

    selectedOpeningTimeName: function() {
      return this.openingTimes[this.selectedOpeningTime].name;
    },

    selectedOpeningTime24Hour: function() {
      return this.openingTimes[this.selectedOpeningTime]['24hour'];
    },

    selectedClosingTimeName: function() {
      return this.closingTimes[this.selectedClosingTime].name;
    },

    selectedClosingTime24Hour: function() {
      return this.closingTimes[this.selectedClosingTime]['24hour'];
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
