// Shared wizard step navigation functionality
// Used by partner-wizard and calendar-wizard controllers

/**
 * Simple debounce utility - waits for pause in calls before executing
 * @param {Function} func - Function to debounce
 * @param {number} wait - Milliseconds to wait
 * @returns {Function} Debounced function
 */
export function debounce(func, wait) {
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
 * Escapes HTML to prevent XSS
 * @param {string} text - Text to escape
 * @returns {string} Escaped HTML
 */
export function escapeHtml(text) {
	const div = document.createElement("div");
	div.textContent = text;
	return div.innerHTML;
}

/**
 * Gets CSRF token from meta tag
 * @returns {string} CSRF token
 */
export function getCSRFToken() {
	const meta = document.querySelector('meta[name="csrf-token"]');
	return meta ? meta.getAttribute("content") : "";
}

/**
 * Common Stimulus values for wizard controllers
 */
export const wizardValues = {
	currentStep: { type: Number, default: 1 },
	totalSteps: { type: Number, default: 3 },
};

/**
 * Common Stimulus targets for wizard controllers
 */
export const wizardTargets = [
	"step",
	"stepIndicator",
	"backButton",
	"continueButton",
	"submitButton",
];

/**
 * Navigate to next step
 * @param {Controller} controller - Stimulus controller with wizard values/targets
 * @param {Function} validateFn - Optional validation function, returns boolean
 * @param {Function} onStepChangeFn - Optional callback after step change
 */
export function nextStep(controller, validateFn, onStepChangeFn) {
	if (controller.currentStepValue < controller.totalStepsValue) {
		if (validateFn && !validateFn()) {
			return;
		}
		controller.currentStepValue++;
		updateWizardUI(controller);
		scrollToTop();
		if (onStepChangeFn) {
			onStepChangeFn(controller.currentStepValue);
		}
	}
}

/**
 * Navigate to previous step
 * @param {Controller} controller - Stimulus controller with wizard values/targets
 * @param {Function} onStepChangeFn - Optional callback after step change
 */
export function previousStep(controller, onStepChangeFn) {
	if (controller.currentStepValue > 1) {
		controller.currentStepValue--;
		updateWizardUI(controller);
		scrollToTop();
		if (onStepChangeFn) {
			onStepChangeFn(controller.currentStepValue);
		}
	}
}

/**
 * Update wizard UI - step visibility, indicators, and navigation buttons
 * @param {Controller} controller - Stimulus controller with wizard targets
 */
export function updateWizardUI(controller) {
	const currentStep = controller.currentStepValue;
	const totalSteps = controller.totalStepsValue;

	// Update step visibility
	if (controller.hasStepTarget) {
		controller.stepTargets.forEach((step) => {
			const stepNum = parseInt(step.dataset.step, 10);
			step.classList.toggle("hidden", stepNum !== currentStep);
		});
	}

	// Update step indicators
	if (controller.hasStepIndicatorTarget) {
		controller.stepIndicatorTargets.forEach((indicator) => {
			const stepNum = parseInt(indicator.dataset.step, 10);
			indicator.classList.toggle("step-primary", stepNum <= currentStep);
		});
	}

	// Update navigation buttons
	if (controller.hasBackButtonTarget) {
		controller.backButtonTarget.classList.toggle("hidden", currentStep === 1);
	}

	if (controller.hasContinueButtonTarget) {
		controller.continueButtonTarget.classList.toggle(
			"hidden",
			currentStep === totalSteps
		);
	}

	if (controller.hasSubmitButtonTarget) {
		controller.submitButtonTarget.classList.toggle(
			"hidden",
			currentStep !== totalSteps
		);
	}
}

/**
 * Scroll to top of page smoothly
 */
export function scrollToTop() {
	window.scrollTo({ top: 0, behavior: "smooth" });
}

/**
 * Add input error styling
 * @param {HTMLElement} input - Input element
 */
export function showInputError(input) {
	if (input) {
		input.classList.add("input-error");
		input.focus();
	}
}

/**
 * Remove input error styling
 * @param {HTMLElement} input - Input element
 */
export function clearInputError(input) {
	if (input) {
		input.classList.remove("input-error");
	}
}

/**
 * Add input success styling
 * @param {HTMLElement} input - Input element
 */
export function showInputSuccess(input) {
	if (input) {
		input.classList.add("input-success");
		input.classList.remove("input-error");
	}
}

/**
 * Clear all input styling
 * @param {HTMLElement} input - Input element
 */
export function clearInputStyling(input) {
	if (input) {
		input.classList.remove("input-error", "input-success");
	}
}
