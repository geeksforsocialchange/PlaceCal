import { Controller } from "@hotwired/stimulus";

// Filters Controller - Toggle filter dropdowns and auto-submit on change
// Used by the public site paginator component
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
			this.formTarget.submit();
		}
	}
}
