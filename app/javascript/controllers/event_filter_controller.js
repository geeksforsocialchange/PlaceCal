import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = [
		"neighbourhood",
		"neighbourhoodDropdown",
		"neighbourhoodText",
	];

	toggleNeighbourhood() {
		this.toggleDropdownHidden(this.neighbourhoodDropdownTarget);
	}

	submitNeighbourhood() {
		this.updateLabel();
		this.toggleDropdownHidden(this.neighbourhoodDropdownTarget, true);
		const form = this.element.querySelector("form");
		if (form) form.requestSubmit();
	}

	resetNeighbourhood() {
		if (this.selectedNeighbourhood) this.selectedNeighbourhood.checked = false;
		this.toggleDropdownHidden(this.neighbourhoodDropdownTarget, true);

		const url = new URL(window.location.href);
		url.searchParams.delete("neighbourhood");
		Turbo.visit(url.toString(), { action: "advance" });
	}

	toggleDropdownHidden(dropdown, hidden) {
		if (!dropdown) return;
		dropdown.classList.toggle("filters__dropdown--hidden", hidden);
	}

	updateLabel() {
		if (this.hasNeighbourhoodTextTarget && this.selectedNeighbourhood?.labels) {
			this.neighbourhoodTextTarget.innerHTML =
				this.selectedNeighbourhood.labels[0].textContent;
		}
	}

	get selectedNeighbourhood() {
		return this.neighbourhoodTargets.find((r) => r.checked);
	}
}
