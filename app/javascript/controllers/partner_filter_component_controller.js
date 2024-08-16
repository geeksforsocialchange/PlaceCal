import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	static targets = ["category", "neighbourhood", "form"];

	connect() {}

	submitCategory() {
		console.log(this.categoryTargets.find((r) => r.checked).value);
		this.formTarget.submit();
	}

	submitNeighbourhood() {
		console.log(this.neighbourhoodTargets.find((r) => r.checked).value);
		this.formTarget.submit();
	}
}
