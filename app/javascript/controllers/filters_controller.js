import { Controller } from "@hotwired/stimulus";

// Filters Controller - Toggle filter dropdowns and auto-submit on change
// Used by the events browser filters component
// Works with Turbo Frames for seamless updates
export default class extends Controller {
	static targets = ["dropdown", "form"];

	toggle(event) {
		event.preventDefault();
		this.dropdownTargets.forEach((dropdown) => {
			dropdown.classList.toggle("filters__dropdown--hidden");
		});
	}

	submit() {
		if (this.hasFormTarget) {
			// Use requestSubmit() for Turbo compatibility
			// This triggers the submit event which Turbo intercepts
			this.formTarget.requestSubmit();
		}
	}
}
