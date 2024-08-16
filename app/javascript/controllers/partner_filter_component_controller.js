import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	static targets = [
		"form",
		"category",
		"categoryText",
		"neighbourhood",
		"neighbourhoodText",
	];

	connect() {
		// Find the associated label for each selected param and get the text contents
		// If params are selected, they show up instead of "Category" and "Neighbourhood" text
		if (this.selectedCategory) {
			this.categoryTextTarget.innerHTML =
				this.selectedCategory.labels[0].textContent;
		}
		if (this.selectedNeighbourhood) {
			this.neighbourhoodTextTarget.innerHTML =
				this.selectedNeighbourhood.labels[0].textContent;
		}
	}

	submitCategory() {
		this.formTarget.submit();
	}

	submitNeighbourhood() {
		this.formTarget.submit();
	}

	resetCategory() {
		this.selectedCategory.checked = false;
		this.formTarget.submit();
	}

	resetNeighbourhood() {
		this.neighbourhoodTargets.find((r) => r.checked).checked = false;
		this.formTarget.submit();
	}

	get selectedCategory() {
		return this.categoryTargets.find((r) => r.checked);
	}

	get selectedNeighbourhood() {
		return this.neighbourhoodTargets.find((r) => r.checked);
	}
}
