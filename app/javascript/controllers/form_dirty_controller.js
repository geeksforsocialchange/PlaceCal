import { Controller } from "@hotwired/stimulus";
import {
	setupFormTracking,
	teardownFormTracking,
	isDirty,
	updateIndicator,
} from "controllers/mixins/form_tracking";

// Simple form dirty tracking controller
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
		// Setup shared form tracking with initial value tracking (for revert detection)
		setupFormTracking(this, {
			tabName: this.tabNameValue,
			form: this.element,
			trackInitialValues: true,
			onDirtyChange: (dirty) => this.updateUI(dirty),
		});

		// Initial UI state
		this.updateUI(false);
	}

	disconnect() {
		teardownFormTracking(this);
	}

	updateUI(dirty) {
		// Update indicator visibility
		if (this.hasIndicatorTarget) {
			updateIndicator(this.indicatorTarget, dirty);
		}

		// Update submit button state
		if (this.hasSubmitTarget) {
			this.submitTarget.disabled = !dirty;
			if (dirty) {
				this.submitTarget.classList.remove(
					"btn-disabled",
					"opacity-50",
					"cursor-not-allowed",
				);
			} else {
				this.submitTarget.classList.add(
					"btn-disabled",
					"opacity-50",
					"cursor-not-allowed",
				);
			}
		}
	}
}
