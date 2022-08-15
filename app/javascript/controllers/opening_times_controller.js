import { Controller } from "@hotwired/stimulus";

/*
 * TODO
 *
 * Form validation - possible to submit times as "" - Neither JS prevents this nor does the model validate it.
 *
 * UI Stuff
 *
 * Full days
 *
 * https://schema.org/OpeningHoursSpecification
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

const sortedOpeningHours = (openSpecArray) => {
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

const removeTime = (openSpecArray, openSpec) =>
	[...openSpecArray].filter(
		(el) => JSON.stringify(el) !== JSON.stringify(openSpec),
	);

const el = (type, content = "") => {
	const el = document.createElement(type);
	el.innerHTML = content;
	return el;
};

// Connects to data-controller="opening-times"
export default class extends Controller {
	static values = { data: Array };
	static targets = ["textarea", "list"];

	connect() {
		this.dataValue = sortedOpeningHours(this.dataValue);
	}

	dataValueChanged() {
		this.updateTextarea();
		this.updateList();
	}

	updateTextarea() {
		this.textareaTarget.value = JSON.stringify(this.dataValue);
	}

	updateList() {
		this.listTarget.innerHTML = "";
		this.dataValue
			.map((openSpec) => {
				const li = el("li", openingHoursEnglish(openSpec) + " [remove X]");
				// remove the option by clicking on the list item - worst UI ever
				li.onclick = () => {
					this.dataValue = removeTime(this.dataValue, openSpec);
				};
				return li;
			})
			.forEach((li) => {
				this.listTarget.append(li);
			});
	}

	addOpeningTime(event) {
		event.preventDefault();
		const day = this.element.querySelector("#day").value;
		const open = this.element.querySelector("#open").value;
		const close = this.element.querySelector("#close").value;
		this.element.querySelector("#day").value = "Monday";
		this.element.querySelector("#open").value = "";
		this.element.querySelector("#close").value = "";
		this.dataValue = sortedOpeningHours([
			...this.dataValue,
			openingHoursSpec(day, open, close),
		]);
	}
}
