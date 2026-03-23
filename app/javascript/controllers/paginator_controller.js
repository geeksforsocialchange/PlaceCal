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

		// Show all buttons to measure layout
		this.buttonTargets.forEach((btn) => (btn.style.display = ""));

		// Detect wrapping: if the forward arrow is on a different line than the
		// back arrow, some items have wrapped and we need to hide a few buttons.
		const backArrow = this.element.querySelector(".paginator__arrow--back");
		const baseTop = backArrow
			? backArrow.offsetTop
			: this.buttonTargets[0].offsetTop;

		if (this.forwardTarget.offsetTop <= baseTop) return; // all fits

		// Hide non-active buttons from the left until the forward arrow
		// is back on the first line. This keeps the active tab visible.
		for (let i = 0; i < this.buttonTargets.length; i++) {
			if (this.forwardTarget.offsetTop <= baseTop) break;
			if (!this.buttonTargets[i].classList.contains("active")) {
				this.buttonTargets[i].style.display = "none";
			}
		}
	}

	debounce(func, wait) {
		let timeout;
		return (...args) => {
			clearTimeout(timeout);
			timeout = setTimeout(() => func.apply(this, args), wait);
		};
	}
}
