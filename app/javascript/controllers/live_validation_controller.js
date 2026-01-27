import { Controller } from "@hotwired/stimulus";

// Live form validation controller
// Add data-controller="live-validation" to a form or container
// Add validation rules to inputs via data attributes:
//   data-validate-required="true"
//   data-validate-min="5"
//   data-validate-max="200"
//   data-validate-email="true"
//   data-validate-url="true"
//   data-validate-message="Custom error message"

export default class extends Controller {
	static values = {
		validateOn: { type: String, default: "blur" }, // "blur", "input", or "both"
	};

	connect() {
		// Bind methods once so we can remove them later
		this.boundValidateField = this.validateField.bind(this);
		this.boundClearErrorOnInput = this.clearErrorOnInput.bind(this);
		this.boundHandleSubmit = this.handleSubmit.bind(this);

		this.inputs = this.element.querySelectorAll(
			"input:not([type=hidden]):not([type=radio]):not([type=checkbox]), textarea, select",
		);

		this.inputs.forEach((input) => {
			// Always validate on blur
			input.addEventListener("blur", this.boundValidateField);

			// Optionally validate on input too
			if (this.validateOnValue === "input" || this.validateOnValue === "both") {
				input.addEventListener("input", this.boundValidateField);
			}

			// Clear error styling when user starts typing
			input.addEventListener("input", this.boundClearErrorOnInput);
		});

		// Validate all fields on form submit
		if (this.element.tagName === "FORM") {
			this.element.addEventListener("submit", this.boundHandleSubmit);
		}
	}

	disconnect() {
		this.inputs.forEach((input) => {
			input.removeEventListener("blur", this.boundValidateField);
			input.removeEventListener("input", this.boundValidateField);
			input.removeEventListener("input", this.boundClearErrorOnInput);
		});

		if (this.element.tagName === "FORM") {
			this.element.removeEventListener("submit", this.boundHandleSubmit);
		}
	}

	validateField(event) {
		const input = event.target;
		const value = input.value.trim();
		const errors = [];

		// Required validation
		if (input.dataset.validateRequired === "true" && !value) {
			errors.push(
				input.dataset.validateRequiredMessage || "This field is required",
			);
		}

		// Min length validation
		if (input.dataset.validateMin && value) {
			const min = parseInt(input.dataset.validateMin, 10);
			if (value.length < min) {
				errors.push(
					input.dataset.validateMinMessage ||
						`Must be at least ${min} characters`,
				);
			}
		}

		// Max length validation
		if (input.dataset.validateMax && value) {
			const max = parseInt(input.dataset.validateMax, 10);
			if (value.length > max) {
				errors.push(
					input.dataset.validateMaxMessage ||
						`Must be no more than ${max} characters`,
				);
			}
		}

		// Email validation
		if (input.dataset.validateEmail === "true" && value) {
			const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
			if (!emailRegex.test(value)) {
				errors.push(
					input.dataset.validateEmailMessage || "Enter a valid email address",
				);
			}
		}

		// URL validation
		if (input.dataset.validateUrl === "true" && value) {
			try {
				new URL(value);
			} catch {
				errors.push(
					input.dataset.validateUrlMessage ||
						"Enter a valid URL (including https://)",
				);
			}
		}

		// Password confirmation validation
		if (input.dataset.validateConfirm && value) {
			const targetInput = document.getElementById(
				input.dataset.validateConfirm,
			);
			if (targetInput && targetInput.value !== value) {
				errors.push(
					input.dataset.validateConfirmMessage || "Passwords do not match",
				);
			}
		}

		// Show or clear errors
		if (errors.length > 0) {
			this.showError(input, errors[0]);
		} else {
			this.clearError(input);
		}
	}

	clearErrorOnInput(event) {
		const input = event.target;
		// Only clear if we're in "blur" mode (not validating on every keystroke)
		if (this.validateOnValue === "blur") {
			// Remove error styling but keep the message until blur re-validates
			input.classList.remove("input-error", "textarea-error", "select-error");
		}
	}

	showError(input, message) {
		// Add error class to input
		if (input.tagName === "TEXTAREA") {
			input.classList.add("textarea-error");
		} else if (input.tagName === "SELECT") {
			input.classList.add("select-error");
		} else {
			input.classList.add("input-error");
		}

		// Find or create error message element
		let errorEl = input.parentElement.querySelector(".validation-error");
		if (!errorEl) {
			errorEl = document.createElement("p");
			errorEl.className =
				"validation-error text-error text-xs mt-1 flex items-center gap-1";
			errorEl.innerHTML = `<svg class="w-3 h-3 shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg><span></span>`;
			input.parentElement.appendChild(errorEl);
		}

		errorEl.querySelector("span").textContent = message;
		errorEl.style.display = "flex";
	}

	clearError(input) {
		// Remove error class
		input.classList.remove("input-error", "textarea-error", "select-error");

		// Hide error message
		const errorEl = input.parentElement.querySelector(".validation-error");
		if (errorEl) {
			errorEl.style.display = "none";
		}
	}

	// Handle form submission
	handleSubmit(event) {
		if (!this.validateAll()) {
			event.preventDefault();
			// Scroll to first error
			const firstError = this.element.querySelector(
				".input-error, .textarea-error, .select-error",
			);
			if (firstError) {
				firstError.scrollIntoView({ behavior: "smooth", block: "center" });
				firstError.focus();
			}
		}
	}

	// Validate all fields (can be called before form submit)
	validateAll() {
		let isValid = true;
		this.inputs.forEach((input) => {
			this.validateField({ target: input });
			if (
				input.classList.contains("input-error") ||
				input.classList.contains("textarea-error") ||
				input.classList.contains("select-error")
			) {
				isValid = false;
			}
		});
		return isValid;
	}
}
