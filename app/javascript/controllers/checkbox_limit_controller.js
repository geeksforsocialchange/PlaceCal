import { Controller } from "@hotwired/stimulus";

// Limits the number of checkboxes that can be selected
export default class extends Controller {
	static values = {
		max: { type: Number, default: 3 },
	};

	connect() {
		this.counter = this.element.querySelector("[data-counter]");
		this.bindCheckboxes();
		this.update();
	}

	bindCheckboxes() {
		const checkboxes = this.checkboxes;
		checkboxes.forEach((cb) => {
			cb.addEventListener("change", () => this.update());
			// Also handle click for browsers/tests that don't fire change properly
			cb.addEventListener("click", () => {
				setTimeout(() => this.update(), 0);
			});
		});
	}

	get checkboxes() {
		return this.element.querySelectorAll('input[type="checkbox"]');
	}

	update() {
		const checkboxes = this.checkboxes;
		const checked = Array.from(checkboxes).filter((cb) => cb.checked);
		const checkedCount = checked.length;
		const atLimit = checkedCount >= this.maxValue;

		// Update counter if present
		if (this.counter) {
			this.counter.textContent = `${checkedCount} / ${this.maxValue}`;

			// Visual feedback when at limit
			this.counter.classList.remove(
				"text-gray-600",
				"text-warning",
				"font-medium",
			);

			if (atLimit) {
				this.counter.classList.add("text-warning", "font-medium");
			} else {
				this.counter.classList.add("text-gray-600");
			}
		}

		// Disable unchecked checkboxes when at limit
		this.checkboxes.forEach((checkbox) => {
			if (!checkbox.checked && atLimit) {
				checkbox.disabled = true;
				checkbox
					.closest("label")
					?.classList.add("opacity-50", "cursor-not-allowed");
			} else {
				checkbox.disabled = false;
				checkbox
					.closest("label")
					?.classList.remove("opacity-50", "cursor-not-allowed");
			}
		});
	}
}
