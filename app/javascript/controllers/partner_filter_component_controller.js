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
		dropdown.classList.toggle("filters__dropdown--hidden", hidden);
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

	get selectedCategory() {
		return this.categoryTargets.find((r) => r.checked);
	}

	get selectedNeighbourhood() {
		return this.neighbourhoodTargets.find((r) => r.checked);
	}
}
