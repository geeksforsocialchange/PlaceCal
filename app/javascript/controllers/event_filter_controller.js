import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["form", "neighbourhoodDropdown", "neighbourhoodText"];

	toggleNeighbourhood() {
		this.neighbourhoodDropdownTarget.classList.toggle(
			"filters__dropdown--hidden",
		);
	}

	submitNeighbourhood(event) {
		// Find the parent form and submit it
		const form = event.target.closest("form");
		if (form) {
			form.requestSubmit();
		}
	}

	resetNeighbourhood(event) {
		event.preventDefault();
		// Find all neighbourhood radio buttons and uncheck them
		const form = event.target.closest("form");
		if (form) {
			const radios = form.querySelectorAll('input[name="neighbourhood"]');
			radios.forEach((radio) => (radio.checked = false));

			// Remove the neighbourhood param by creating a new URL without it
			const url = new URL(window.location.href);
			url.searchParams.delete("neighbourhood");

			// Navigate using Turbo
			Turbo.visit(url.toString(), { action: "advance" });
		}
	}
}
