import { Controller } from "@hotwired/stimulus";

// Tracks form changes and updates UI accordingly
// - Shows/hides unsaved changes indicator
// - Enables/disables submit button until changes are made
// - Warns before leaving page with unsaved changes
//
// Usage:
//   <form data-controller="form-dirty">
//     <div data-form-dirty-target="indicator" class="hidden">Unsaved changes</div>
//     <button data-form-dirty-target="submit" disabled>Save</button>
//   </form>

export default class extends Controller {
	static targets = ["indicator", "submit"];

	static values = {
		tabName: { type: String, default: "" }, // Tab radio name to exclude from tracking
	};

	connect() {
		this.dirty = false;
		this.initialValues = new Map();

		// Store initial values
		this.trackableInputs.forEach((input) => {
			this.initialValues.set(input, this.getInputValue(input));
		});

		// Bind change listeners
		this.trackableInputs.forEach((input) => {
			input.addEventListener("input", this.checkDirty.bind(this));
			input.addEventListener("change", this.checkDirty.bind(this));
		});

		// Track file inputs separately (they can only be "changed", not reverted)
		this.element.querySelectorAll('input[type="file"]').forEach((input) => {
			input.addEventListener("change", () => this.markDirty());
		});

		// Warn before leaving with unsaved changes
		this.boundBeforeUnload = this.handleBeforeUnload.bind(this);
		window.addEventListener("beforeunload", this.boundBeforeUnload);

		// Initial UI state
		this.updateUI();
	}

	disconnect() {
		window.removeEventListener("beforeunload", this.boundBeforeUnload);
	}

	get trackableInputs() {
		return Array.from(
			this.element.querySelectorAll(
				"input:not([type=hidden]):not([type=file]), textarea, select"
			)
		).filter((input) => {
			// Exclude tab radios
			if (this.tabNameValue && input.name === this.tabNameValue) return false;
			// Exclude hidden system fields
			if (input.type === "hidden") return false;
			return true;
		});
	}

	getInputValue(input) {
		if (input.type === "checkbox" || input.type === "radio") {
			return input.checked;
		}
		return input.value;
	}

	checkDirty() {
		let hasChanges = false;

		this.trackableInputs.forEach((input) => {
			const initial = this.initialValues.get(input);
			const current = this.getInputValue(input);
			if (initial !== current) {
				hasChanges = true;
			}
		});

		if (hasChanges !== this.dirty) {
			this.dirty = hasChanges;
			this.updateUI();
		}
	}

	markDirty() {
		if (!this.dirty) {
			this.dirty = true;
			this.updateUI();
		}
	}

	updateUI() {
		// Update indicator visibility
		if (this.hasIndicatorTarget) {
			if (this.dirty) {
				this.indicatorTarget.classList.remove("hidden");
				this.indicatorTarget.classList.add("flex");
			} else {
				this.indicatorTarget.classList.add("hidden");
				this.indicatorTarget.classList.remove("flex");
			}
		}

		// Update submit button state
		if (this.hasSubmitTarget) {
			this.submitTarget.disabled = !this.dirty;
			if (this.dirty) {
				this.submitTarget.classList.remove(
					"btn-disabled",
					"opacity-50",
					"cursor-not-allowed"
				);
			} else {
				this.submitTarget.classList.add(
					"btn-disabled",
					"opacity-50",
					"cursor-not-allowed"
				);
			}
		}
	}

	handleBeforeUnload(event) {
		if (this.dirty) {
			event.preventDefault();
			event.returnValue = "You have unsaved changes.";
			return event.returnValue;
		}
	}
}
