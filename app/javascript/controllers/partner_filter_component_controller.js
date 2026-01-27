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
		this.hideDropdown(this.categoryDropdownTarget);
		this.submitForm();
	}

	submitNeighbourhood() {
		this.updateLabels();
		this.hideDropdown(this.neighbourhoodDropdownTarget);
		this.submitForm();
	}

	resetCategory() {
		this.selectedCategory.checked = false;
		this.hideDropdown(this.categoryDropdownTarget);
		this.submitForm();
	}

	resetNeighbourhood() {
		this.selectedNeighbourhood.checked = false;
		this.hideDropdown(this.neighbourhoodDropdownTarget);
		this.submitForm();
	}

	toggleCategory() {
		this.categoryDropdownTarget.classList.toggle("filters__dropdown--hidden");
		// Close other dropdown
		if (this.hasNeighbourhoodDropdownTarget) {
			this.neighbourhoodDropdownTarget.classList.add(
				"filters__dropdown--hidden"
			);
		}
	}

	toggleNeighbourhood() {
		this.neighbourhoodDropdownTarget.classList.toggle(
			"filters__dropdown--hidden"
		);
		// Close other dropdown
		if (this.hasCategoryDropdownTarget) {
			this.categoryDropdownTarget.classList.add("filters__dropdown--hidden");
		}
	}

	hideDropdown(dropdown) {
		if (dropdown) {
			dropdown.classList.add("filters__dropdown--hidden");
		}
	}

	updateLabels() {
		// Find the associated label for each selected param and get the text contents
		// If params are selected, they show up instead of "Category" and "Neighbourhood" text
		if (this.hasCategoryTextTarget && this.selectedCategory) {
			this.categoryTextTarget.innerHTML =
				this.selectedCategory.labels[0].textContent;
		}
		if (this.hasNeighbourhoodTextTarget && this.selectedNeighbourhood) {
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
