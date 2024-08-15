import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	connect() {
		console.log("connected!!");
	}
}
