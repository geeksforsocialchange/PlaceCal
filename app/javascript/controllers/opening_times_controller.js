import { Controller } from "@hotwired/stimulus";

/*
 * TODO
 *
 * Handle 12+24hr time inputs (determined by user system settings 😬)
 * 24hr format = string "12:22"
 * 12hr format = ???
 *
 * Convert from form input to openingTimesSpecification and back.
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
			.map((timeObj) => el("li", JSON.stringify(timeObj)))
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
		console.log(open);
		this.dataValue = [...this.dataValue, { day, open, close }];
	}
}
