import { Controller } from "@hotwired/stimulus";

// Dropdown Controller - Simple dropdown menu toggle
export default class extends Controller {
	static targets = ["menu"];

	connect() {
		// Close dropdown when clicking outside
		this.outsideClickHandler = this.closeOnOutsideClick.bind(this);
		document.addEventListener("click", this.outsideClickHandler);
	}

	disconnect() {
		document.removeEventListener("click", this.outsideClickHandler);
	}

	toggle(event) {
		event.stopPropagation();
		this.menuTarget.classList.toggle("hidden");
	}

	close() {
		this.menuTarget.classList.add("hidden");
	}

	closeOnOutsideClick(event) {
		if (!this.element.contains(event.target)) {
			this.close();
		}
	}
}
