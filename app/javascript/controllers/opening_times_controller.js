import { Controller } from "@hotwired/stimulus";

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

	update(event) {
		event.preventDefault();
		console.log("CLICKED");
		const day = this.element.querySelector("#day").value;
		const open = this.element.querySelector("#open").value;
		const close = this.element.querySelector("#close").value;
		this.dataValue = [...this.dataValue, { day, open, close }];
	}
}
