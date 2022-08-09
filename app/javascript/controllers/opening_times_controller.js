import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="opening-times"
export default class extends Controller {
	static values = { data: Array };
	static targets = ["textarea"];
	connect() {
		console.log("CONNECTED");
		console.log(this.hasDataValue);
		console.log(this.dataValue);
	}

	dataValueChanged() {
		this.updateTextarea();
	}

	updateTextarea() {
		console.log("running");
		this.textareaTarget.value = JSON.stringify(this.dataValue);
	}
}
