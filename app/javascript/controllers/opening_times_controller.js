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
	static targets = ["textarea", "list", "day", "allDay", "open", "close"];

	connect() {
		this.dataValue = sortedOpeningHours(this.dataValue);
		this.resetForm();
	}

	resetForm() {
		this.dayTarget.value = "Monday";
		this.allDayTarget.checked = false;
		this.openTarget.value = "";
		this.closeTarget.value = "";
		this.openTarget.disabled = false;
		this.closeTarget.disabled = false;
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

	allDay(event) {
		event.preventDefault();
		if (this.allDayTarget.checked) {
			this.openTarget.value = "00:00";
			this.closeTarget.value = "23:59";
			this.openTarget.disabled = true;
			this.closeTarget.disabled = true;
		}
		if (!this.allDayTarget.checked) {
			this.openTarget.disabled = false;
			this.closeTarget.disabled = false;
		}
	}

	addOpeningTime(event) {
		event.preventDefault();
		const day = this.dayTarget.value;
		const open = this.openTarget.value;
		const close = this.closeTarget.value;
		this.resetForm();
		this.dataValue = sortedOpeningHours([
			...this.dataValue,
			openingHoursSpec(day, open, close),
		]);
	}
}
