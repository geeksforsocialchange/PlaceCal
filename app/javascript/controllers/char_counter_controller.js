import { Controller } from "@hotwired/stimulus";

// Character counter with visual feedback as limit approaches
export default class extends Controller {
	static targets = ["input", "counter", "bar"];
	static values = {
		max: { type: Number, default: 200 },
		warningAt: { type: Number, default: 80 }, // percentage
		dangerAt: { type: Number, default: 95 }, // percentage
	};

	connect() {
		this.update();
	}

	update() {
		const length = this.inputTarget.value.length;
		const max = this.maxValue;
		const percent = (length / max) * 100;
		const remaining = max - length;

		// Update counter text
		if (this.hasCounterTarget) {
			this.counterTarget.textContent = `${length} / ${max}`;

			// Update counter styling based on thresholds
			this.counterTarget.classList.remove(
				"text-base-content/40",
				"text-placecal-orange",
				"text-error",
				"font-medium"
			);

			if (percent >= this.dangerAtValue) {
				this.counterTarget.classList.add("text-error", "font-medium");
			} else if (percent >= this.warningAtValue) {
				this.counterTarget.classList.add("text-placecal-orange", "font-medium");
			} else {
				this.counterTarget.classList.add("text-base-content/40");
			}
		}

		// Update progress bar if present
		if (this.hasBarTarget) {
			this.barTarget.style.width = `${Math.min(percent, 100)}%`;

			this.barTarget.classList.remove(
				"bg-base-300",
				"bg-placecal-orange",
				"bg-error"
			);

			if (percent >= this.dangerAtValue) {
				this.barTarget.classList.add("bg-error");
			} else if (percent >= this.warningAtValue) {
				this.barTarget.classList.add("bg-placecal-orange");
			} else {
				this.barTarget.classList.add("bg-base-300");
			}
		}
	}
}
