import { Controller } from "@hotwired/stimulus";
import isEqual from "lodash/isEqual";
import orderBy from "lodash/orderBy";

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
	// Get last segment of URL (e.g., "Monday" from "http://schema.org/Monday")
	day: openSpec.dayOfWeek.split("/").pop(),
	open: openSpec.opens.slice(0, 5),
	close: openSpec.closes.slice(0, 5),
});

const sortedOpeningHours = (openSpecArray) =>
	orderBy(openSpecArray, [
		(el) => dayOrder.indexOf(openingHoursObj(el).day),
		(el) => parseFloat(openingHoursObj(el).open.replace(":", ".")),
	]);

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
	static targets = [
		"textarea",
		"list",
		"day",
		"allDay",
		"open",
		"close",
		"empty",
	];

	connect() {
		this.dataValue = sortedOpeningHours(this.dataValue);
		this.resetForm();
		// Ensure empty state is correct on initial load
		this.updateEmptyState();
	}

	disconnect() {
		// clear nodes & eventListeners which don't have stimulus attributes
		// This might be unnecessary
		this.listTarget.replaceChildren();
	}

	resetForm(day = "Monday", open = "09:00", close = "17:00") {
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
		this.updateEmptyState();
	}

	updateTextarea() {
		this.textareaTarget.value = JSON.stringify(this.dataValue);
	}

	updateEmptyState() {
		if (this.hasEmptyTarget) {
			this.emptyTarget.classList.toggle("hidden", this.dataValue.length > 0);
		}
	}

	updateList() {
		this.listTarget.replaceChildren(
			...this.dataValue.map((openSpec) => {
				// Create a clean row for each opening time
				const row = element("div", "", [
					"flex",
					"items-center",
					"justify-between",
					"bg-base-100",
					"rounded-lg",
					"px-4",
					"py-3",
				]);

				const text = element("span", openingHoursEnglish(openSpec), [
					"text-base",
					"font-medium",
				]);

				const btn = element("button", "", [
					"btn",
					"btn-ghost",
					"btn-sm",
					"btn-square",
					"text-base-content/40",
					"hover:text-error",
					"hover:bg-error/10",
				]);
				btn.type = "button";
				btn.innerHTML = `<svg class="size-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6 7h12M9 7V5a1 1 0 011-1h4a1 1 0 011 1v2m2 0v11a2 2 0 01-2 2H9a2 2 0 01-2-2V7h10z"/></svg>`;
				btn.onclick = () => {
					this.dataValue = [...this.dataValue].filter(
						(el) => !isEqual(el, openSpec)
					);
				};

				row.appendChild(text);
				row.appendChild(btn);
				return row;
			})
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
