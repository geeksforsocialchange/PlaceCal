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
// ?TODO?  Convert this function to use Array find() rather than reduce() ?
//      ?  It would be a lot more compact, but I'm not sure whether I should
//      ?  include EcmaScript 6 functions.
//
function addedDay(spec) {
  console.log(spec);
  return {
    dayName: daysArray.reduce( function(acc,val) {
      if (acc) {
        return acc;
      } else if (val['schema.org'] == spec.dayOfWeek){
        return val.name;
      } else {
        return false
      }
    }, false)

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
    selectedOpeningTime:  {
      hh: '09',
      mm: '00',
      a: 'AM'
    },
    selectedClosingTime: {
      hh: '05',
      mm: '00',
      a: 'PM'
    },
    days: daysArray,
  },

  computed: {

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
