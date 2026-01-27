import { Controller } from "@hotwired/stimulus";

// Paginator Controller - Responsive pagination buttons
// Hides buttons that would overflow past the forward arrow
export default class extends Controller {
	static targets = ["button", "forward"];

	connect() {
		this.updateButtons();
		this.resizeHandler = this.debounce(() => this.updateButtons(), 100);
		window.addEventListener("resize", this.resizeHandler);
	}

	disconnect() {
		window.removeEventListener("resize", this.resizeHandler);
	}

	updateButtons() {
		if (this.buttonTargets.length === 0 || !this.hasForwardTarget) return;

		const rightThreshold = this.forwardTarget.offsetLeft - 30;

		this.buttonTargets.forEach((button) => {
			button.style.display = "";
			const rightEdge = button.offsetLeft + button.offsetWidth;
			if (rightEdge >= rightThreshold) {
				button.style.display = "none";
			}
		});
	}

	debounce(func, wait) {
		let timeout;
		return (...args) => {
			clearTimeout(timeout);
			timeout = setTimeout(() => func.apply(this, args), wait);
		};
	}
}
