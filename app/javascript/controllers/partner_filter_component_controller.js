import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	static targets = ["category", "neighbourhood"];

	connect() {
		console.log(this.element);
	}

	submitCategory() {
		console.log(this.categoryTargets.find((r) => r.checked).value);
	}

	submitNeighbourhood() {
		console.log(this.neighbourhoodTargets.find((r) => r.checked).value);
	}
}
