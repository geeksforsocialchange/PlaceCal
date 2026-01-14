import { Controller } from "@hotwired/stimulus";

/**
 * Simple debounce utility - waits for pause in calls before executing
 */
function debounce(func, wait) {
	let timeout;
	return function executedFunction(...args) {
		const later = () => {
			clearTimeout(timeout);
			func.apply(this, args);
		};
		clearTimeout(timeout);
		timeout = setTimeout(later, wait);
	};
}

/**
 * Calendar Wizard Controller
 * Handles step navigation and source URL validation for new calendar form
 */
export default class extends Controller {
	static targets = [
		"step",
		"stepIndicator",
		"sourceInput",
		"importerModeSection",
		"importerModeSelect",
		"sourceFeedback",
		"sourceSuccess",
		"sourceError",
		"sourceErrorMessage",
		"detectedFormat",
		"detectedFormatName",
		"testButton",
		"testSpinner",
		"testIconNeutral",
		"testIconSuccess",
		"testIconError",
		"testButtonText",
		"partnerSelect",
		"nameInput",
		"nameSuggestion",
		"backButton",
		"continueButton",
		"submitButton",
	];

	static values = {
		currentStep: { type: Number, default: 1 },
		totalSteps: { type: Number, default: 3 },
		testUrl: String,
		sourceValid: { type: Boolean, default: false },
		nameSuffix: { type: String, default: " Calendar" },
	};

	connect() {
		this.testSourceDebounced = debounce(this.performSourceTest.bind(this), 600);
		this.updateUI();
		this.updateContinueButton();

		// Wait for tom-select to initialize on partner dropdown
		setTimeout(() => {
			this.setupPartnerListener();
			this.updateContinueButton();
		}, 100);
	}

	// Step navigation
	nextStep() {
		if (this.currentStepValue < this.totalStepsValue) {
			if (!this.validateCurrentStep()) {
				return;
			}
			this.currentStepValue++;
			this.updateUI();
			this.scrollToTop();

			// Update name suggestion when entering step 2
			if (this.currentStepValue === 2) {
				this.updateNameSuggestion();
			}
		}
	}

	previousStep() {
		if (this.currentStepValue > 1) {
			this.currentStepValue--;
			this.updateUI();
			this.scrollToTop();
		}
	}

	// Check if current step is valid (without showing errors)
	isCurrentStepValid() {
		if (this.currentStepValue === 1) {
			return this.sourceValidValue;
		} else if (this.currentStepValue === 2) {
			const partnerValue = this.getPartnerValue();
			const nameValue = this.hasNameInputTarget
				? this.nameInputTarget.value.trim()
				: "";
			return partnerValue && nameValue.length >= 3;
		}
		// Step 3 has no required fields
		return true;
	}

	validateCurrentStep() {
		if (this.currentStepValue === 1) {
			// Step 1: Source URL must be valid
			if (!this.sourceValidValue) {
				this.sourceInputTarget.classList.add("input-error");
				this.sourceInputTarget.focus();
				return false;
			}
		} else if (this.currentStepValue === 2) {
			// Step 2: Partner and name are required
			const partnerValue = this.getPartnerValue();
			const nameValue = this.nameInputTarget.value.trim();

			if (!partnerValue) {
				this.partnerSelectTarget.classList.add("input-error");
				return false;
			}
			if (nameValue.length < 3) {
				this.nameInputTarget.classList.add("input-error");
				this.nameInputTarget.focus();
				return false;
			}
		}
		return true;
	}

	updateContinueButton() {
		const isValid = this.isCurrentStepValid();
		const btn = this.continueButtonTarget;

		if (isValid) {
			btn.classList.remove("btn-disabled", "opacity-50");
			btn.classList.add(
				"bg-placecal-orange",
				"hover:bg-orange-600",
				"text-white"
			);
		} else {
			btn.classList.add("btn-disabled", "opacity-50");
			btn.classList.remove("hover:bg-orange-600");
		}
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

		// Update continue button state for new step
		this.updateContinueButton();
	}

	scrollToTop() {
		window.scrollTo({ top: 0, behavior: "smooth" });
	}

	// Source URL testing
	sourceChanged() {
		// Reset validation state when source changes
		this.sourceValidValue = false;
		this.hideFeedback();
		this.sourceInputTarget.classList.remove("input-error", "input-success");
		this.resetTestButton();
		this.updateContinueButton();
	}

	resetTestButton() {
		const btn = this.testButtonTarget;
		// Reset to orange state
		btn.classList.remove(
			"bg-success",
			"hover:bg-success",
			"text-success-content",
			"border-success",
			"bg-error",
			"hover:bg-error",
			"text-error-content",
			"border-error"
		);
		btn.classList.add(
			"bg-placecal-orange",
			"hover:bg-orange-600",
			"text-white",
			"border-placecal-orange"
		);
		// Reset icon and text
		this.testIconNeutralTarget.classList.remove("hidden");
		this.testIconSuccessTarget.classList.add("hidden");
		this.testIconErrorTarget.classList.add("hidden");
		this.testButtonTextTarget.textContent = "Test";
	}

	setTestButtonSuccess() {
		const btn = this.testButtonTarget;
		// Green button
		btn.classList.remove(
			"bg-placecal-orange",
			"hover:bg-orange-600",
			"text-white",
			"border-placecal-orange",
			"bg-error",
			"hover:bg-error",
			"text-error-content",
			"border-error"
		);
		btn.classList.add(
			"bg-success",
			"hover:bg-success",
			"text-success-content",
			"border-success"
		);
		// Update icon and text
		this.testIconNeutralTarget.classList.add("hidden");
		this.testIconSuccessTarget.classList.remove("hidden");
		this.testIconErrorTarget.classList.add("hidden");
		this.testButtonTextTarget.textContent = "OK!";
	}

	setTestButtonError() {
		const btn = this.testButtonTarget;
		// Red button
		btn.classList.remove(
			"bg-placecal-orange",
			"hover:bg-orange-600",
			"text-white",
			"border-placecal-orange",
			"bg-success",
			"hover:bg-success",
			"text-success-content",
			"border-success"
		);
		btn.classList.add(
			"bg-error",
			"hover:bg-error",
			"text-error-content",
			"border-error"
		);
		// Update icon and text
		this.testIconNeutralTarget.classList.add("hidden");
		this.testIconSuccessTarget.classList.add("hidden");
		this.testIconErrorTarget.classList.remove("hidden");
		this.testButtonTextTarget.textContent = "Error";
	}

	testSource() {
		this.performSourceTest();
	}

	async performSourceTest() {
		const source = this.sourceInputTarget.value.trim();

		if (!source) {
			return;
		}

		// Show loading state - hide all icons, show spinner
		this.testButtonTarget.disabled = true;
		this.testSpinnerTarget.classList.remove("hidden");
		this.testIconNeutralTarget.classList.add("hidden");
		this.testIconSuccessTarget.classList.add("hidden");
		this.testIconErrorTarget.classList.add("hidden");
		this.hideFeedback();

		try {
			const response = await fetch(this.testUrlValue, {
				method: "POST",
				credentials: "same-origin",
				headers: {
					"Content-Type": "application/json",
					Accept: "application/json",
					"X-CSRF-Token": this.getCSRFToken(),
				},
				body: JSON.stringify({ source: source }),
			});

			const data = await response.json();

			this.sourceFeedbackTarget.classList.remove("hidden");

			if (data.valid) {
				// Success - show detected format
				this.sourceValidValue = true;
				this.sourceSuccessTarget.classList.remove("hidden");
				this.sourceInputTarget.classList.add("input-success");
				this.sourceInputTarget.classList.remove("input-error");
				this.setTestButtonSuccess();

				// Show the importer mode section
				if (this.hasImporterModeSectionTarget) {
					this.importerModeSectionTarget.classList.remove("hidden");
				}

				// Auto-select the detected importer mode
				if (data.importer_key && data.importer_key !== "auto") {
					this.importerModeSelectTarget.value = data.importer_key;
					this.detectedFormatTarget.classList.remove("hidden");
					this.detectedFormatNameTarget.textContent = data.importer_name;
				}
			} else {
				// Error
				this.sourceValidValue = false;
				this.sourceErrorTarget.classList.remove("hidden");
				this.sourceErrorMessageTarget.textContent =
					data.error || "Unable to validate this URL";
				this.sourceInputTarget.classList.add("input-error");
				this.sourceInputTarget.classList.remove("input-success");
				this.setTestButtonError();
			}
		} catch (error) {
			console.error("Error testing source:", error);
			this.sourceValidValue = false;
			this.sourceFeedbackTarget.classList.remove("hidden");
			this.sourceErrorTarget.classList.remove("hidden");
			this.sourceErrorMessageTarget.textContent =
				"Connection error. Please try again.";
			this.sourceInputTarget.classList.add("input-error");
			this.setTestButtonError();
		} finally {
			this.testButtonTarget.disabled = false;
			this.testSpinnerTarget.classList.add("hidden");
			this.updateContinueButton();
		}
	}

	hideFeedback() {
		this.sourceFeedbackTarget.classList.add("hidden");
		this.sourceSuccessTarget.classList.add("hidden");
		this.sourceErrorTarget.classList.add("hidden");
		this.detectedFormatTarget.classList.add("hidden");
		if (this.hasImporterModeSectionTarget) {
			this.importerModeSectionTarget.classList.add("hidden");
		}
	}

	getCSRFToken() {
		const meta = document.querySelector('meta[name="csrf-token"]');
		return meta ? meta.getAttribute("content") : "";
	}

	// Partner selection and name suggestion
	setupPartnerListener() {
		const tomSelect = this.partnerSelectTarget.tomselect;
		if (tomSelect) {
			tomSelect.on("change", () => this.partnerChanged());
		}
	}

	partnerChanged() {
		this.partnerSelectTarget.classList.remove("input-error");
		this.updateNameSuggestion();
		this.updateContinueButton();
	}

	getPartnerValue() {
		const tomSelect = this.partnerSelectTarget.tomselect;
		if (tomSelect) {
			return tomSelect.getValue();
		}
		return this.partnerSelectTarget.value;
	}

	getPartnerName() {
		const tomSelect = this.partnerSelectTarget.tomselect;
		if (tomSelect) {
			const selectedItem = tomSelect.getItem(tomSelect.getValue());
			if (selectedItem) {
				return selectedItem.textContent.trim();
			}
		} else if (
			this.partnerSelectTarget.selectedOptions &&
			this.partnerSelectTarget.selectedOptions[0]
		) {
			const selectedOption = this.partnerSelectTarget.selectedOptions[0];
			if (selectedOption.value) {
				return selectedOption.text;
			}
		}
		return "";
	}

	updateNameSuggestion() {
		if (!this.hasNameSuggestionTarget) return;

		const partnerName = this.getPartnerName();
		const nameValue = this.nameInputTarget.value.trim();

		// Only show suggestion if name is empty and partner is selected
		if (partnerName && !nameValue) {
			const suggestedName = partnerName + this.nameSuffixValue;
			this.nameSuggestionTarget.dataset.suggestedName = suggestedName;
			this.nameSuggestionTarget.classList.remove("hidden");
		} else {
			this.nameSuggestionTarget.classList.add("hidden");
		}
	}

	applySuggestion() {
		const suggestedName = this.nameSuggestionTarget.dataset.suggestedName;
		if (suggestedName) {
			this.nameInputTarget.value = suggestedName;
			this.nameSuggestionTarget.classList.add("hidden");
			this.nameInputTarget.classList.remove("input-error");
			this.nameInputTarget.dispatchEvent(
				new Event("change", { bubbles: true })
			);
			this.updateContinueButton();
		}
	}

	nameChanged() {
		this.nameInputTarget.classList.remove("input-error");
		this.updateNameSuggestion();
		this.updateContinueButton();
	}

	escapeHtml(text) {
		const div = document.createElement("div");
		div.textContent = text;
		return div.innerHTML;
	}
}
