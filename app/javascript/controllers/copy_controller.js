import { Controller } from "@hotwired/stimulus";

// Copies the source field's value, briefly swapping the button text for the copied or failed label
export default class extends Controller {
	static targets = ["source", "button"];
	static values = { copiedLabel: String, failedLabel: String };

	connect() {
		this.label = this.buttonTarget.textContent;
	}

	async copy() {
		try {
			await navigator.clipboard.writeText(this.sourceTarget.value);
			this.flash(this.copiedLabelValue);
		} catch {
			this.flash(this.failedLabelValue);
		}
	}

	flash(text) {
		this.buttonTarget.textContent = text;
		clearTimeout(this.reset);
		this.reset = setTimeout(() => {
			this.buttonTarget.textContent = this.label;
		}, 2000);
	}

	disconnect() {
		clearTimeout(this.reset);
	}
}
