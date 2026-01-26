import { Controller } from "@hotwired/stimulus";
import {
	debounce,
	escapeHtml,
	wizardValues,
	wizardTargets,
	nextStep,
	previousStep,
	updateWizardUI,
	showInputError,
	showInputSuccess,
	clearInputStyling,
	setContinueButtonEnabled,
} from "controllers/mixins/wizard";

/**
 * User Wizard Controller
 * Handles step navigation and email validation for the new user form
 */
export default class extends Controller {
	static targets = [
		...wizardTargets,
		"form",
		"emailInput",
		"emailFeedback",
		"emailAvailable",
		"emailTaken",
		"emailTakenLink",
		"emailInvalid",
	];

	static values = {
		...wizardValues,
		emailValid: { type: Boolean, default: false },
		emailAvailable: { type: Boolean, default: false },
	};

	connect() {
		this.checkEmailDebounced = debounce(this.performEmailCheck.bind(this), 400);
		updateWizardUI(this);
		this.updateContinueButton();
	}

	// Step navigation
	nextStep() {
		nextStep(
			this,
			() => this.validateCurrentStep(),
			() => this.updateContinueButton()
		);
	}

	previousStep() {
		previousStep(this, () => this.updateContinueButton());
	}

	// Check if current step is valid (without showing errors)
	isCurrentStepValid() {
		if (this.currentStepValue === 1) {
			return this.emailValidValue && this.emailAvailableValue;
		}
		// Step 2 (permissions) has no required fields
		return true;
	}

	validateCurrentStep() {
		if (this.currentStepValue === 1) {
			const email = this.emailInputTarget.value.trim();
			if (!email || !this.emailValidValue || !this.emailAvailableValue) {
				showInputError(this.emailInputTarget);
				return false;
			}
		}
		return true;
	}

	updateContinueButton() {
		if (this.hasContinueButtonTarget) {
			setContinueButtonEnabled(
				this.continueButtonTarget,
				this.isCurrentStepValid()
			);
		}
	}

	// Email validation
	checkEmail() {
		this.checkEmailDebounced();
	}

	async performEmailCheck() {
		const email = this.emailInputTarget.value.trim();

		// Reset UI state
		this.hideFeedback();
		clearInputStyling(this.emailInputTarget);
		this.emailValidValue = false;
		this.emailAvailableValue = false;
		this.updateContinueButton();

		if (!email) {
			return;
		}

		// Basic client-side format validation first
		if (!this.isValidEmailFormat(email)) {
			this.showInvalidFeedback();
			return;
		}

		try {
			const response = await fetch(
				`/users/lookup_email?email=${encodeURIComponent(email)}`,
				{
					method: "GET",
					credentials: "same-origin",
					headers: {
						Accept: "application/json",
					},
				}
			);

			const data = await response.json();

			if (!data.valid) {
				this.showInvalidFeedback();
				return;
			}

			this.emailValidValue = true;

			if (data.available) {
				this.emailAvailableValue = true;
				this.showAvailableFeedback();
			} else {
				this.emailAvailableValue = false;
				this.showTakenFeedback(data.existing_user);
			}
		} catch (error) {
			console.error("Error checking email:", error);
		} finally {
			this.updateContinueButton();
		}
	}

	isValidEmailFormat(email) {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
	}

	hideFeedback() {
		if (this.hasEmailFeedbackTarget) {
			this.emailFeedbackTarget.classList.add("hidden");
		}
		if (this.hasEmailAvailableTarget) {
			this.emailAvailableTarget.classList.add("hidden");
		}
		if (this.hasEmailTakenTarget) {
			this.emailTakenTarget.classList.add("hidden");
		}
		if (this.hasEmailInvalidTarget) {
			this.emailInvalidTarget.classList.add("hidden");
		}
	}

	showInvalidFeedback() {
		showInputError(this.emailInputTarget);
		if (this.hasEmailFeedbackTarget) {
			this.emailFeedbackTarget.classList.remove("hidden");
		}
		if (this.hasEmailInvalidTarget) {
			this.emailInvalidTarget.classList.remove("hidden");
		}
	}

	showAvailableFeedback() {
		showInputSuccess(this.emailInputTarget);
		if (this.hasEmailFeedbackTarget) {
			this.emailFeedbackTarget.classList.remove("hidden");
		}
		if (this.hasEmailAvailableTarget) {
			this.emailAvailableTarget.classList.remove("hidden");
		}
	}

	showTakenFeedback(existingUser) {
		showInputError(this.emailInputTarget);
		if (this.hasEmailFeedbackTarget) {
			this.emailFeedbackTarget.classList.remove("hidden");
		}
		if (this.hasEmailTakenTarget) {
			this.emailTakenTarget.classList.remove("hidden");
			if (this.hasEmailTakenLinkTarget && existingUser) {
				this.emailTakenLinkTarget.href = `/users/${existingUser.id}/edit`;
				const name =
					existingUser.first_name || existingUser.last_name
						? escapeHtml(
								`${existingUser.first_name || ""} ${
									existingUser.last_name || ""
								}`.trim()
						  )
						: "this user";
				this.emailTakenLinkTarget.textContent = `View ${name}`;
			}
		}
	}
}
