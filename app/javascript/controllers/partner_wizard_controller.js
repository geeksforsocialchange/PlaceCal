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
	clearInputError,
} from "./mixins/wizard";

/**
 * Partner Wizard Controller
 * Handles step navigation and name validation for the new partner form
 */
export default class extends Controller {
	static targets = [
		...wizardTargets,
		"form",
		"nameInput",
		"nameFeedback",
		"exactMatch",
		"exactMatchLink",
		"similarSection",
		"similarList",
		"nameAvailable",
	];

	static values = {
		...wizardValues,
	};

	connect() {
		this.checkNameDebounced = debounce(this.performNameCheck.bind(this), 400);
		updateWizardUI(this);
	}

	// Step navigation
	nextStep() {
		nextStep(this, () => this.validateCurrentStep());
	}

	previousStep() {
		previousStep(this);
	}

	validateCurrentStep() {
		if (this.currentStepValue === 1) {
			const name = this.nameInputTarget.value.trim();
			if (name.length < 5) {
				showInputError(this.nameInputTarget);
				return false;
			}
			clearInputError(this.nameInputTarget);
		}
		return true;
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
							<span class="flex-1">${escapeHtml(partner.name)}</span>
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
}
