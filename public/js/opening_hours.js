Vue.component('added-days', {
  props: ['list'],

  template: '#added-days-template',

  methods: {
    removeDay: function(day) {
      console.log('removed... ');
      console.log(day);
      this.list.splice(day, 1);
    },
  }
})

new Vue({
  el: '#opening-times',

  data: {
    addedDays: [],
    selectedDay: 0,
    selectedOpeningTime: 8,
    selectedClosingTime: 17,
    days: [
      { value: 0, name: 'Monday', "schema.org": "http://schema.org/Monday" },
      { value: 1, name: 'Tuesday', "schema.org": "http://schema.org/Tuesday" },
      { value: 2, name: 'Wednesday', "schema.org": "http://schema.org/Wednesday" },
      { value: 3, name: 'Thursday', "schema.org": "http://schema.org/Thursday" },
      { value: 4, name: 'Friday', "schema.org": "http://schema.org/Friday" },
      { value: 5, name: 'Saturday', "schema.org": "http://schema.org/Saturday" },
      { value: 6, name: 'Sunday', "schema.org": "http://schema.org/Sunday" },
    ],
    openingTimes: [
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
    ],
    closingTimes: [
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
    ]
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
      console.log("Yep. Here, honest.")
      return this.closingTimes[this.selectedClosingTime]['24hour'];
    }

  },

  // {
  //     "@type": "OpeningHoursSpecification",
  //     "closes":  "17:00:00",
  //     "dayOfWeek": "http://schema.org/Sunday",
  //     "opens":  "09:00:00"
  // }

  methods: {
    addDay: function() {
      var day =
      {
        "@type": "OpeningHoursSpecification",
        "closes": this.selectedClosingTime24Hour,
        "dayOfWeek": this.selectedDaySchemaDotOrg,
        "opens": this.selectedOpeningTime24Hour,

        // id: this.selectedDay,
        // dayName: this.selectedDayName,
        // openingTimeName: this.selectedOpeningTimeName,
        // closingTimeName: this.selectedClosingTimeName,
      }
      console.log(day.closes)
      this.addedDays.push(day);
    },
  }
})
