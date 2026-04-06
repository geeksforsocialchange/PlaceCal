import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	static targets = [
		"form",
		"partnership",
		"partnershipText",
		"partnershipDropdown",
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

	submitPartnership() {
		this.updateLabels();
		this.hideDropdown(this.partnershipDropdownTarget);
		this.submitForm();
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

	resetPartnership() {
		this.selectedPartnership.checked = false;
		this.hideDropdown(this.partnershipDropdownTarget);
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

	togglePartnership() {
		this.partnershipDropdownTarget.classList.toggle(
			"filters__dropdown--hidden",
		);
		// Close other dropdowns
		if (this.hasCategoryDropdownTarget) {
			this.categoryDropdownTarget.classList.add("filters__dropdown--hidden");
		}
		if (this.hasNeighbourhoodDropdownTarget) {
			this.neighbourhoodDropdownTarget.classList.add(
				"filters__dropdown--hidden",
			);
		}
	}

	toggleCategory() {
		this.categoryDropdownTarget.classList.toggle("filters__dropdown--hidden");
		// Close other dropdowns
		if (this.hasPartnershipDropdownTarget) {
			this.partnershipDropdownTarget.classList.add("filters__dropdown--hidden");
		}
		if (this.hasNeighbourhoodDropdownTarget) {
			this.neighbourhoodDropdownTarget.classList.add(
				"filters__dropdown--hidden",
			);
		}
	}

	toggleNeighbourhood() {
		this.neighbourhoodDropdownTarget.classList.toggle(
			"filters__dropdown--hidden",
		);
		// Close other dropdowns
		if (this.hasPartnershipDropdownTarget) {
			this.partnershipDropdownTarget.classList.add("filters__dropdown--hidden");
		}
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
		// If params are selected, they show up instead of "Partnership", "Category" and "Neighbourhood" text
		if (this.hasPartnershipTextTarget && this.selectedPartnership) {
			this.partnershipTextTarget.innerHTML =
				this.selectedPartnership.labels[0].textContent;
		}
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

	get selectedPartnership() {
		return this.partnershipTargets.find((r) => r.checked);
	}

	get selectedCategory() {
		return this.categoryTargets.find((r) => r.checked);
	}

	get selectedNeighbourhood() {
		return this.neighbourhoodTargets.find((r) => r.checked);
	}
}
