import { Controller } from "@hotwired/stimulus";

// Mobile Menu Controller - Toggle mobile navigation menu
// Used by the public site navigation component
export default class extends Controller {
	static targets = ["menu"];

	connect() {
		// Start with menu hidden on mobile
		this.menuTarget.classList.add("is-hidden");
	}

	toggle() {
		this.menuTarget.classList.toggle("is-hidden");
	}
}
