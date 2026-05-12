import { Controller } from "@hotwired/stimulus";

// Paginator Controller - Responsive pagination buttons
// Hides buttons that would overflow past the forward arrow
export default class extends Controller {
	static targets = ["button", "forward"];

	connect() {
		this.resizeHandler = this.debounce(() => this.updateButtons(), 100);
		window.addEventListener("resize", this.resizeHandler);

		// Run updateButtons at several points because layout can shift
		// after Stimulus connects: once now, once on the next frame, and
		// once after web fonts settle (chip widths depend on the font).
		this.updateButtons();
		requestAnimationFrame(() => this.updateButtons());
		document.fonts?.ready?.then(() => this.updateButtons());
	}

	disconnect() {
		window.removeEventListener("resize", this.resizeHandler);
	}

	updateButtons() {
		if (this.buttonTargets.length === 0) return;

		// Show all buttons to measure layout
		this.buttonTargets.forEach((btn) => (btn.style.display = ""));

		// Detect wrapping by comparing the first and last day chip. The
		// back/forward arrows are absolutely positioned so their offsetTop
		// is always 0 and can't be used here.
		const firstButton = this.buttonTargets[0];
		const lastButton = this.buttonTargets[this.buttonTargets.length - 1];
		if (lastButton.offsetTop <= firstButton.offsetTop) return; // all fits

		// Hide non-active buttons from the left until the last chip is
		// back on the first line. This keeps the active tab visible.
		for (let i = 0; i < this.buttonTargets.length; i++) {
			if (lastButton.offsetTop <= firstButton.offsetTop) break;
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
