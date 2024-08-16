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
		this.categoryTextTarget.innerHTML = this.categoryTargets.find(
			(r) => r.checked
		).labels[0].textContent;
		this.neighbourhoodTextTarget.innerHTML = this.neighbourhoodTargets.find(
			(r) => r.checked
		).labels[0].textContent;
	}

	submitCategory() {
		this.formTarget.submit();
	}

	submitNeighbourhood() {
		this.formTarget.submit();
	}

	resetCategory() {
		this.categoryTargets.find((r) => r.checked).checked = false;
		this.formTarget.submit();
	}

	resetNeighbourhood() {
		this.neighbourhoodTargets.find((r) => r.checked).checked = false;
		this.formTarget.submit();
	}
}
