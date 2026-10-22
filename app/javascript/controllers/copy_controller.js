import { Controller } from "@hotwired/stimulus";

// Copies the source field's value, briefly swapping the button text for the copied label
export default class extends Controller {
	static targets = ["source", "button"];
	static values = { copiedLabel: String };

	connect() {
		this.label = this.buttonTarget.textContent;
	}

	async copy() {
		await navigator.clipboard.writeText(this.sourceTarget.value);
		this.buttonTarget.textContent = this.copiedLabelValue;
		clearTimeout(this.reset);
		this.reset = setTimeout(() => {
			this.buttonTarget.textContent = this.label;
		}, 2000);
	}

	disconnect() {
		clearTimeout(this.reset);
	}
}
