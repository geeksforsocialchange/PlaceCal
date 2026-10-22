import { Controller } from "@hotwired/stimulus";

// Copies the source field's value, briefly swapping the button text for the copied label
export default class extends Controller {
	static targets = ["source", "button"];
	static values = { copiedLabel: String };

	async copy() {
		await navigator.clipboard.writeText(this.sourceTarget.value);
		const label = this.buttonTarget.textContent;
		this.buttonTarget.textContent = this.copiedLabelValue;
		setTimeout(() => {
			this.buttonTarget.textContent = label;
		}, 2000);
	}
}
