import { Controller } from "@hotwired/stimulus";

/*
 * TODO
 *
 * The value of the time input is always in 24-hour format that includes leading zeros: hh:mm
 *
 * Convert from form input to openingTimesSpecification and back.
 * {
  "@context": "https://schema.org",
  "@type": "Store",
  "name": "Middle of Nowhere Foods",
  "openingHours": "Mo,Tu,We,Th,Fr,Sa,Su 09:00-14:00",
  "openingHoursSpecification":
  [
    {
      "@type": "OpeningHoursSpecification",
      "validFrom": "2013-12-24",
      "validThrough": "2013-12-25",
      "opens": "09:00:00",
      "closes": "11:00:00"
    },
    {
      "@type": "OpeningHoursSpecification",
      "validFrom": "2014-01-01",
      "validThrough": "2014-01-01",
      "opens": "12:00:00",
      "closes": "14:00:00"
    }
  ]
}

{
	"@type": "OpeningHoursSpecification",
	closes: "16:00:00",
	dayOfWeek: "http://schema.org/Monday",
	opens: "10:00:00",
}

 *
 * Read exising opening time and display in human readable language
 *
 * Display in chronological order, not creation order
 *
 * Remove an entry, probably .filter on the array, maybe create a closure for the test
 * added to the onclick of the remove button that embeds the opening times to remove?
 * Not sure how that will work with stimulus
 *
 * */

const openingHoursSpec = (day, open, close) => ({
	"@type": "OpeningHoursSpecification",
	dayOfWeek: `http://schema.org/${day}`,
	opens: `${open}:00`,
	closes: `${close}:00`,
});

const openingHoursObj = (openSpec) => ({
	day: openSpec.dayOfWeek.split("/").filter((str) => str.includes("day"))[0],
	open: openSpec.opens.slice(0, 5),
	close: openSpec.closes.slice(0, 5),
});

const sortOpeningHours = (openSpecArray) => {
	const dayOrder = [
		"Monday",
		"Tuesday",
		"Wednesday",
		"Thursday",
		"Friday",
		"Saturday",
		"Sunday",
	];
	return [...openSpecArray]
		.sort((a, b) => openingHoursObj(a).open > openingHoursObj(b).open)
		.sort(
			(a, b) =>
				dayOrder.indexOf(openingHoursObj(a).day) >
				dayOrder.indexOf(openingHoursObj(b).day),
		);
};

const openingHoursEnglish = (openSpec) => {
	const { day, open, close } = openingHoursObj(openSpec);
	return `${day} from ${open} to ${close}`;
};

const el = (type, content) => {
	const el = document.createElement(type);
	el.innerHTML = content;
	return el;
};

// Connects to data-controller="opening-times"
export default class extends Controller {
	static values = { data: Array };
	static targets = ["textarea", "list"];
	connect() {
		console.log("CONNECTED");
		console.log(this.hasDataValue);
		console.log(this.dataValue);
		this.dataValue = sortOpeningHours(this.dataValue);
	}

	dataValueChanged() {
		this.updateTextarea();
		this.updateList();
	}

	updateTextarea() {
		console.log("running");
		this.textareaTarget.value = JSON.stringify(this.dataValue);
	}

	updateList() {
		this.listTarget.innerHTML = "";
		console.log("walking");
		this.dataValue
			.map((timeObj) => el("li", openingHoursEnglish(timeObj)))
			.forEach((element) => {
				this.listTarget.append(element);
			});
	}

	updateFromForm(event) {
		event.preventDefault();
		console.log("CLICKED");
		const day = this.element.querySelector("#day").value;
		const open = this.element.querySelector("#open").value;
		const close = this.element.querySelector("#close").value;
		this.dataValue = sortOpeningHours([
			...this.dataValue,
			openingHoursSpec(day, open, close),
		]);
	}
}
