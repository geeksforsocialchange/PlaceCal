import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	static targets = [
		"form",
		"category",
		"categoryText",
		"categoryDropdown",
		"neighbourhood",
		"neighbourhoodText",
		"neighbourhoodDropdown",
	];

	connect() {
		this.updateLabels();
	}

	submitCategory() {
		this.updateLabels();
		this.toggleDropdownHidden(this.categoryDropdownTarget, true);
		this.submitForm();
	}

	submitNeighbourhood() {
		this.updateLabels();
		this.toggleDropdownHidden(this.neighbourhoodDropdownTarget, true);
		this.submitForm();
	}

	resetCategory() {
		if (this.selectedCategory) this.selectedCategory.checked = false;
		this.toggleDropdownHidden(this.categoryDropdownTarget, true);
		this.submitForm();
	}

	resetNeighbourhood() {
		if (this.selectedNeighbourhood) this.selectedNeighbourhood.checked = false;
		this.toggleDropdownHidden(this.neighbourhoodDropdownTarget, true);
		this.submitForm();
	}

	toggleCategory() {
		this.toggleDropdownHidden(this.categoryDropdownTarget);
		if (this.hasNeighbourhoodDropdownTarget) {
			this.toggleDropdownHidden(this.neighbourhoodDropdownTarget, true);
		}
	}

	toggleNeighbourhood() {
		this.toggleDropdownHidden(this.neighbourhoodDropdownTarget);
		if (this.hasCategoryDropdownTarget) {
			this.toggleDropdownHidden(this.categoryDropdownTarget, true);
		}
	}

	toggleDropdownHidden(dropdown, hidden) {
		if (!dropdown) return;
		const closed = hidden ?? dropdown.dataset.state !== "closed";
		dropdown.dataset.state = closed ? "closed" : "open";
	}

	updateLabels() {
		if (this.hasCategoryTextTarget && this.selectedCategory?.labels) {
			this.categoryTextTarget.innerHTML =
				this.selectedCategory.labels[0].textContent;
		}
		if (this.hasNeighbourhoodTextTarget && this.selectedNeighbourhood?.labels) {
			this.neighbourhoodTextTarget.innerHTML =
				this.selectedNeighbourhood.labels[0].textContent;
		}
	}

	submitForm() {
		this.formTarget.requestSubmit();
	}

	// Enter fires change (which submits) and then the browser's own submit; two frame visits race.
	guardSubmit(event) {
		if (this.submitting) {
			event.preventDefault();
			return;
		}
		this.submitting = true;
		setTimeout(() => {
			this.submitting = false;
		});
	}

	// The clear button empties the field with a plain input/search event (no inputType), never a change.
	submitIfCleared(event) {
		if (event.target.value === "" && !event.inputType) this.submitForm();
	}

	get selectedCategory() {
		return this.categoryTargets.find((r) => r.checked);
	}

	get selectedNeighbourhood() {
		return this.neighbourhoodTargets.find((r) => r.checked);
	}
}
