import { Controller } from "@hotwired/stimulus";

// Reveal Controller - Expandable content sections
// Used by the public site for "read more" sections
export default class extends Controller {
	static targets = ["button"];
	static values = {
		openText: { type: String, default: "Close" },
		closedText: { type: String, default: "Open to read more" },
	};

	connect() {
		this.isVisible = false;
		this.element.classList.add("is-hidden");
	}

	toggle(event) {
		event.preventDefault();
		this.isVisible = !this.isVisible;
		this.element.classList.toggle("is-hidden");

		if (this.hasButtonTarget) {
			this.buttonTarget.textContent = this.isVisible
				? this.openTextValue
				: this.closedTextValue;
		}
	}
}
