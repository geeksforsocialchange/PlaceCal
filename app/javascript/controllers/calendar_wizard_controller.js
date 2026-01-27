import { Controller } from "@hotwired/stimulus";
import {
	debounce,
	getCSRFToken,
	wizardValues,
	wizardTargets,
	nextStep,
	previousStep,
	updateWizardUI,
	showInputError,
	clearInputError,
	showInputSuccess,
	clearInputStyling,
	setContinueButtonEnabled,
} from "controllers/mixins/wizard";

/**
 * Calendar Wizard Controller
 * Handles step navigation and source URL validation for new calendar form
 */
export default class extends Controller {
	static targets = [
		...wizardTargets,
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
		"placeSelect",
		"continueButtonText",
	];

	static values = {
		...wizardValues,
		testUrl: String,
		sourceValid: { type: Boolean, default: false },
		detectedFormat: { type: String, default: "" },
	};

	connect() {
		this.testSourceDebounced = debounce(this.performSourceTest.bind(this), 600);
		updateWizardUI(this);
		this.updateContinueButton();

		// Wait for tom-select to initialize on partner dropdown
		setTimeout(() => {
			this.setupPartnerListener();
			this.updateContinueButton();
		}, 100);
	}

	// Step navigation
	nextStep() {
		nextStep(
			this,
			() => this.validateCurrentStep(),
			(step) => this.onStepChange(step),
		);
	}

	previousStep() {
		previousStep(this, (step) => this.onStepChange(step));
	}

	onStepChange(step) {
		this.updateContinueButton();

		// Update name suggestion when entering step 2
		if (step === 2) {
			this.updateNameSuggestion();
		}

		// Auto-select partner as default location when entering step 3
		if (step === 3) {
			this.autoSelectPartnerAsPlace();
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
				showInputError(this.sourceInputTarget);
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
				showInputError(this.nameInputTarget);
				return false;
			}
		}
		return true;
	}

	updateContinueButton() {
		if (this.hasContinueButtonTarget) {
			setContinueButtonEnabled(
				this.continueButtonTarget,
				this.isCurrentStepValid(),
			);
		}

		// Update button text based on step and validation state
		if (this.hasContinueButtonTextTarget) {
			if (this.currentStepValue === 1 && this.sourceValidValue) {
				this.continueButtonTextTarget.textContent = "Save & Continue";
			} else {
				this.continueButtonTextTarget.textContent = "Continue";
			}
		}
	}

	// Source URL testing
	sourceChanged() {
		// Reset validation state when source changes
		this.sourceValidValue = false;
		this.hideFeedback();
		clearInputStyling(this.sourceInputTarget);
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
			"border-error",
		);
		btn.classList.add(
			"bg-placecal-orange",
			"hover:bg-orange-600",
			"text-white",
			"border-placecal-orange",
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
			"border-error",
		);
		btn.classList.add(
			"bg-success",
			"hover:bg-success",
			"text-success-content",
			"border-success",
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
			"border-success",
		);
		btn.classList.add(
			"bg-error",
			"hover:bg-error",
			"text-error-content",
			"border-error",
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
					"X-CSRF-Token": getCSRFToken(),
				},
				body: JSON.stringify({ source: source }),
			});

			const data = await response.json();

			this.sourceFeedbackTarget.classList.remove("hidden");

			if (data.valid) {
				// Success - show detected format
				this.sourceValidValue = true;
				this.sourceSuccessTarget.classList.remove("hidden");
				showInputSuccess(this.sourceInputTarget);
				this.setTestButtonSuccess();

				// Show the importer mode section
				if (this.hasImporterModeSectionTarget) {
					this.importerModeSectionTarget.classList.remove("hidden");
				}

				// Auto-select the detected importer mode and store format name
				if (data.importer_key && data.importer_key !== "auto") {
					this.importerModeSelectTarget.value = data.importer_key;
					this.detectedFormatTarget.classList.remove("hidden");
					this.detectedFormatNameTarget.textContent = data.importer_name;
					this.detectedFormatValue = data.importer_name;
				}
			} else {
				// Error
				this.sourceValidValue = false;
				this.sourceErrorTarget.classList.remove("hidden");
				this.sourceErrorMessageTarget.textContent =
					data.error || "Unable to validate this URL";
				showInputError(this.sourceInputTarget);
				this.setTestButtonError();
			}
		} catch (error) {
			console.error("Error testing source:", error);
			this.sourceValidValue = false;
			this.sourceFeedbackTarget.classList.remove("hidden");
			this.sourceErrorTarget.classList.remove("hidden");
			this.sourceErrorMessageTarget.textContent =
				"Connection error. Please try again.";
			showInputError(this.sourceInputTarget);
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
		const partnerName = this.getPartnerName();
		const nameValue = this.nameInputTarget.value.trim();

		// Auto-fill name when partner is selected and name is empty
		if (partnerName && !nameValue) {
			const calendarType = this.detectedFormatValue || "Calendar";
			const suggestedName = `${partnerName} | ${calendarType}`;
			this.nameInputTarget.value = suggestedName;
			clearInputError(this.nameInputTarget);
			this.updateContinueButton();
		}
	}

	nameChanged() {
		clearInputError(this.nameInputTarget);
		this.updateNameSuggestion();
		this.updateContinueButton();
	}

	// Auto-select the partner as the default location
	autoSelectPartnerAsPlace() {
		if (!this.hasPlaceSelectTarget) return;

		const partnerValue = this.getPartnerValue();
		if (!partnerValue) return;

		// Wait for tom-select to initialize on place dropdown
		setTimeout(() => {
			const tomSelect = this.placeSelectTarget.tomselect;
			if (tomSelect) {
				// Only set if the option exists and nothing is already selected
				if (tomSelect.options[partnerValue] && !tomSelect.getValue()) {
					tomSelect.setValue(partnerValue);
				}
			} else if (!this.placeSelectTarget.value) {
				// Fallback to native select
				this.placeSelectTarget.value = partnerValue;
			}
		}, 100);
	}
}
