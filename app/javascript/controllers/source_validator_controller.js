import { Controller } from "@hotwired/stimulus";
import { debounce, getCSRFToken } from "./mixins/wizard";

/**
 * Source Validator Controller
 * Validates calendar source URLs against the test endpoint
 * Can be used standalone or within the calendar wizard
 */
export default class extends Controller {
	static targets = [
		"input",
		"feedback",
		"success",
		"error",
		"errorMessage",
		"detectedFormat",
		"detectedFormatName",
		"testButton",
		"testSpinner",
		"testIconNeutral",
		"testIconSuccess",
		"testIconError",
		"testButtonText",
		"importerModeSection",
		"importerModeSelect",
	];

	static values = {
		testUrl: String,
		valid: { type: Boolean, default: false },
		detectedFormat: { type: String, default: "" },
	};

	connect() {
		this.testSourceDebounced = debounce(this.performSourceTest.bind(this), 600);

		// Check if source already has a value (edit form)
		if (this.hasInputTarget && this.inputTarget.value.trim()) {
			// Mark as provisionally valid for existing calendars
			this.validValue = true;
		}
	}

	// Called when source input changes
	sourceChanged() {
		this.validValue = false;
		this.hideFeedback();
		this.clearInputStyling();
		this.resetTestButton();
		this.dispatch("changed", { detail: { valid: false } });
	}

	// Manual test trigger
	testSource() {
		this.performSourceTest();
	}

	async performSourceTest() {
		const source = this.inputTarget.value.trim();

		if (!source) {
			return;
		}

		// Show loading state
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

			this.feedbackTarget.classList.remove("hidden");

			if (data.valid) {
				this.validValue = true;
				this.successTarget.classList.remove("hidden");
				this.showInputSuccess();
				this.setTestButtonSuccess();

				// Show importer mode section if available
				if (this.hasImporterModeSectionTarget) {
					this.importerModeSectionTarget.classList.remove("hidden");
				}

				// Auto-select detected importer
				if (data.importer_key && data.importer_key !== "auto") {
					if (this.hasImporterModeSelectTarget) {
						this.importerModeSelectTarget.value = data.importer_key;
					}
					if (this.hasDetectedFormatTarget) {
						this.detectedFormatTarget.classList.remove("hidden");
						this.detectedFormatNameTarget.textContent = data.importer_name;
					}
					this.detectedFormatValue = data.importer_name;
				}

				this.dispatch("validated", {
					detail: {
						valid: true,
						importerKey: data.importer_key,
						importerName: data.importer_name,
					},
				});
			} else {
				this.validValue = false;
				this.errorTarget.classList.remove("hidden");
				this.errorMessageTarget.textContent =
					data.error || "Unable to validate this URL";
				this.showInputError();
				this.setTestButtonError();

				this.dispatch("validated", {
					detail: { valid: false, error: data.error },
				});
			}
		} catch (error) {
			console.error("Error testing source:", error);
			this.validValue = false;
			this.feedbackTarget.classList.remove("hidden");
			this.errorTarget.classList.remove("hidden");
			this.errorMessageTarget.textContent =
				"Connection error. Please try again.";
			this.showInputError();
			this.setTestButtonError();

			this.dispatch("validated", {
				detail: { valid: false, error: "Connection error" },
			});
		} finally {
			this.testButtonTarget.disabled = false;
			this.testSpinnerTarget.classList.add("hidden");
		}
	}

	hideFeedback() {
		if (this.hasFeedbackTarget) this.feedbackTarget.classList.add("hidden");
		if (this.hasSuccessTarget) this.successTarget.classList.add("hidden");
		if (this.hasErrorTarget) this.errorTarget.classList.add("hidden");
		if (this.hasDetectedFormatTarget)
			this.detectedFormatTarget.classList.add("hidden");
		if (this.hasImporterModeSectionTarget)
			this.importerModeSectionTarget.classList.add("hidden");
	}

	resetTestButton() {
		if (!this.hasTestButtonTarget) return;

		const btn = this.testButtonTarget;
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

		if (this.hasTestIconNeutralTarget)
			this.testIconNeutralTarget.classList.remove("hidden");
		if (this.hasTestIconSuccessTarget)
			this.testIconSuccessTarget.classList.add("hidden");
		if (this.hasTestIconErrorTarget)
			this.testIconErrorTarget.classList.add("hidden");
		if (this.hasTestButtonTextTarget)
			this.testButtonTextTarget.textContent = "Test";
	}

	setTestButtonSuccess() {
		if (!this.hasTestButtonTarget) return;

		const btn = this.testButtonTarget;
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

		if (this.hasTestIconNeutralTarget)
			this.testIconNeutralTarget.classList.add("hidden");
		if (this.hasTestIconSuccessTarget)
			this.testIconSuccessTarget.classList.remove("hidden");
		if (this.hasTestIconErrorTarget)
			this.testIconErrorTarget.classList.add("hidden");
		if (this.hasTestButtonTextTarget)
			this.testButtonTextTarget.textContent = "OK!";
	}

	setTestButtonError() {
		if (!this.hasTestButtonTarget) return;

		const btn = this.testButtonTarget;
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

		if (this.hasTestIconNeutralTarget)
			this.testIconNeutralTarget.classList.add("hidden");
		if (this.hasTestIconSuccessTarget)
			this.testIconSuccessTarget.classList.add("hidden");
		if (this.hasTestIconErrorTarget)
			this.testIconErrorTarget.classList.remove("hidden");
		if (this.hasTestButtonTextTarget)
			this.testButtonTextTarget.textContent = "Error";
	}

	clearInputStyling() {
		this.inputTarget.classList.remove("input-error", "input-success");
	}

	showInputError() {
		this.inputTarget.classList.remove("input-success");
		this.inputTarget.classList.add("input-error");
	}

	showInputSuccess() {
		this.inputTarget.classList.remove("input-error");
		this.inputTarget.classList.add("input-success");
	}
}
