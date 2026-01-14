import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

/**
 * Partner Wizard Controller
 * Handles step navigation and name validation for the new partner form
 */
export default class extends Controller {
	static targets = [
		"form",
		"step",
		"stepIndicator",
		"nameInput",
		"nameFeedback",
		"exactMatch",
		"exactMatchLink",
		"similarSection",
		"similarList",
		"nameAvailable",
		"backButton",
		"continueButton",
		"submitButton",
	];

	static values = {
		currentStep: { type: Number, default: 1 },
		totalSteps: { type: Number, default: 3 },
	};

	connect() {
		this.checkNameDebounced = _.debounce(this.performNameCheck.bind(this), 400);
		this.updateUI();
	}

	// Step navigation
	nextStep() {
		if (this.currentStepValue < this.totalStepsValue) {
			// Validate current step before proceeding
			if (!this.validateCurrentStep()) {
				return;
			}
			this.currentStepValue++;
			this.updateUI();
			this.scrollToTop();
		}
	}

	previousStep() {
		if (this.currentStepValue > 1) {
			this.currentStepValue--;
			this.updateUI();
			this.scrollToTop();
		}
	}

	validateCurrentStep() {
		if (this.currentStepValue === 1) {
			const name = this.nameInputTarget.value.trim();
			if (name.length < 5) {
				this.nameInputTarget.classList.add("input-error");
				this.nameInputTarget.focus();
				return false;
			}
			this.nameInputTarget.classList.remove("input-error");
		}
		return true;
	}

	updateUI() {
		// Update step visibility
		this.stepTargets.forEach((step) => {
			const stepNum = parseInt(step.dataset.step, 10);
			step.classList.toggle("hidden", stepNum !== this.currentStepValue);
		});

		// Update step indicators
		this.stepIndicatorTargets.forEach((indicator) => {
			const stepNum = parseInt(indicator.dataset.step, 10);
			indicator.classList.toggle(
				"step-primary",
				stepNum <= this.currentStepValue
			);
		});

		// Update navigation buttons
		this.backButtonTarget.classList.toggle(
			"hidden",
			this.currentStepValue === 1
		);
		this.continueButtonTarget.classList.toggle(
			"hidden",
			this.currentStepValue === this.totalStepsValue
		);
		this.submitButtonTarget.classList.toggle(
			"hidden",
			this.currentStepValue !== this.totalStepsValue
		);
	}

	scrollToTop() {
		window.scrollTo({ top: 0, behavior: "smooth" });
	}

	// Name validation
	checkName() {
		this.checkNameDebounced();
	}

	async performNameCheck() {
		const name = this.nameInputTarget.value.trim();

		// Reset UI state
		this.nameFeedbackTarget.classList.add("hidden");
		this.exactMatchTarget.classList.add("hidden");
		this.similarSectionTarget.classList.add("hidden");
		this.nameAvailableTarget.classList.add("hidden");
		this.nameInputTarget.classList.remove("input-error", "input-success");

		if (name.length < 5) {
			return;
		}

		try {
			const response = await fetch(
				`/partners/lookup_name?name=${encodeURIComponent(name)}`,
				{
					method: "GET",
					credentials: "same-origin",
					headers: {
						Accept: "application/json",
					},
				}
			);

			const data = await response.json();

			// Show feedback container
			this.nameFeedbackTarget.classList.remove("hidden");

			if (!data.name_available && data.exact_match) {
				// Exact match found - show warning
				this.exactMatchTarget.classList.remove("hidden");
				this.exactMatchLinkTarget.href = `/partners/${data.exact_match.id}/edit`;
				this.nameInputTarget.classList.add("input-error");
			} else if (data.name_available) {
				// Name is available
				this.nameAvailableTarget.classList.remove("hidden");
				this.nameInputTarget.classList.add("input-success");
			}

			// Show similar partners if any
			if (data.similar && data.similar.length > 0) {
				this.similarSectionTarget.classList.remove("hidden");
				this.similarListTarget.innerHTML = data.similar
					.map(
						(partner) => `
						<a href="/partners/${partner.id}/edit"
						   class="flex items-center gap-2 px-3 py-2 rounded-lg bg-base-200 hover:bg-base-300 transition-colors text-sm"
						   target="_blank">
							<span class="flex-1">${this.escapeHtml(partner.name)}</span>
							<span class="text-xs text-base-content/50">View →</span>
						</a>
					`
					)
					.join("");
			}
		} catch (error) {
			console.error("Error checking partner name:", error);
		}
	}

	escapeHtml(text) {
		const div = document.createElement("div");
		div.textContent = text;
		return div.innerHTML;
	}
}
