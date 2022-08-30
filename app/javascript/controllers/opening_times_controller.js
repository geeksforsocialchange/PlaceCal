import { Controller } from "@hotwired/stimulus";

const dayOrder = [
	"Monday",
	"Tuesday",
	"Wednesday",
	"Thursday",
	"Friday",
	"Saturday",
	"Sunday",
];

// https://schema.org/OpeningHoursSpecification
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

const sortedOpeningHours = (openSpecArray) =>
	[...openSpecArray]
		.sort(
			(a, b) =>
				parseFloat(openingHoursObj(a).open.replace(":", ".")) -
				parseFloat(openingHoursObj(b).open.replace(":", ".")),
		)
		.sort(
			(a, b) =>
				dayOrder.indexOf(openingHoursObj(a).day) -
				dayOrder.indexOf(openingHoursObj(b).day),
		);

const nextDay = (day) => {
	const index =
		dayOrder.indexOf(day) + 1 < dayOrder.length ? dayOrder.indexOf(day) + 1 : 0;
	return dayOrder[index];
};

const openingHoursEnglish = (openSpec) => {
	const { day, open, close } = openingHoursObj(openSpec);
	return open === "00:00" && close === "23:59"
		? `${day} all day`
		: `${day} from ${open} to ${close}`;
};

const removeTime = (openSpecArray, openSpec) =>
	[...openSpecArray].filter(
		(el) => JSON.stringify(el) !== JSON.stringify(openSpec),
	);

const element = (type, content = "", classes = []) => {
	const el = document.createElement(type);
	el.innerHTML = content;
	classes.forEach((className) => {
		el.classList.add(className);
	});
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

	disconnect() {
		// clear nodes & eventListeners which don't have stimulus attributes
		// This might be unnecessary
		this.listTarget.replaceChildren();
	}

	resetForm(day = "Monday", open = "00:00", close = "00:00") {
		const allDay = open === "00:00" && close === "23:59";
		this.dayTarget.value = day;
		this.allDayTarget.checked = allDay;
		this.openTarget.value = open;
		this.closeTarget.value = close;
		this.openTarget.disabled = allDay;
		this.closeTarget.disabled = allDay;
	}

	dataValueChanged() {
		this.updateTextarea();
		this.updateList();
	}

	updateTextarea() {
		this.textareaTarget.value = JSON.stringify(this.dataValue);
	}

	updateList() {
		this.listTarget.replaceChildren(
			// This function takes separate params so we map and spread the data array.
			...this.dataValue.map((openSpec) => {
				const li = element("li", openingHoursEnglish(openSpec), [
					"list-group-item",
					"d-flex",
					"align-items-center",
					"justify-content-between",
				]);
				const btn = element("button", "Remove", [
					"btn",
					"btn-danger",
					"btn-sm",
				]);
				btn.onclick = () => {
					this.dataValue = removeTime(this.dataValue, openSpec);
				};
				li.appendChild(btn);
				return li;
			}),
		);
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
		this.resetForm(nextDay(day), open, close);
		this.dataValue = sortedOpeningHours([
			...this.dataValue,
			openingHoursSpec(day, open, close),
		]);
	}
}
