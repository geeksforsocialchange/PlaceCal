import { Controller } from "@hotwired/stimulus";

// Inverts a toggle's value and updates visual state
// Used for "hidden" field where visual "on" = visible (hidden=false)
export default class extends Controller {
	static targets = [
		"checkbox",
		"hidden",
		"card",
		"icon",
		"iconHidden",
		"iconVisible",
		"title",
		"status",
	];

	connect() {
		this.sync();
	}

	toggle() {
		// When checkbox is checked (toggle right/visible), hidden should be false (0)
		// When checkbox is unchecked (toggle left/hidden), hidden should be true (1)
		const isVisible = this.checkboxTarget.checked;
		this.hiddenTarget.value = isVisible ? "0" : "1";
		this.updateVisuals(!isVisible);
	}

	sync() {
		// Sync checkbox state with hidden field on load
		const isHidden = this.hiddenTarget.value === "1";
		this.checkboxTarget.checked = !isHidden;
		this.updateVisuals(isHidden);
	}

	updateVisuals(isHidden) {
		// Update card styling
		if (this.hasCardTarget) {
			if (isHidden) {
				this.cardTarget.classList.remove("bg-base-200/50", "border-base-300");
				this.cardTarget.classList.add("bg-error/5", "border-error/30");
			} else {
				this.cardTarget.classList.remove("bg-error/5", "border-error/30");
				this.cardTarget.classList.add("bg-base-200/50", "border-base-300");
			}
		}

		// Update icon background
		if (this.hasIconTarget) {
			if (isHidden) {
				this.iconTarget.classList.remove("bg-warning/10");
				this.iconTarget.classList.add("bg-error/10");
			} else {
				this.iconTarget.classList.remove("bg-error/10");
				this.iconTarget.classList.add("bg-warning/10");
			}
		}

		// Toggle icon visibility
		if (this.hasIconHiddenTarget && this.hasIconVisibleTarget) {
			this.iconHiddenTarget.classList.toggle("hidden", !isHidden);
			this.iconVisibleTarget.classList.toggle("hidden", isHidden);
		}

		// Update title
		if (this.hasTitleTarget) {
			this.titleTarget.textContent = isHidden
				? "Partner is hidden"
				: "Partner is visible";
			this.titleTarget.classList.toggle("text-error", isHidden);
		}

		// Update status message
		if (this.hasStatusTarget) {
			this.statusTarget.classList.toggle("hidden", !isHidden);
		}
	}
}
