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

		if (!this.wraps()) return; // all fits

		// Hide tabs from the right, then from the left, never the active one,
		// so the visible tabs stay a run with no gaps.
		const active = this.buttonTargets.findIndex((btn) =>
			btn.classList.contains("active"),
		);
		const indexes = [...this.buttonTargets.keys()];
		const hidingOrder = [
			...indexes.slice(active + 1).reverse(),
			...indexes.slice(0, Math.max(active, 0)),
		];
		for (const i of hidingOrder) {
			if (!this.wraps()) break;
			this.buttonTargets[i].style.display = "none";
		}
	}

	// Whether any shown tab has wrapped below the first
	wraps() {
		const shown = this.buttonTargets.filter(
			(btn) => btn.style.display !== "none",
		);
		return shown.some((btn) => btn.offsetTop > shown[0].offsetTop);
	}

	debounce(func, wait) {
		let timeout;
		return (...args) => {
			clearTimeout(timeout);
			timeout = setTimeout(() => func.apply(this, args), wait);
		};
	}
}
