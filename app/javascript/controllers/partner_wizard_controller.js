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
	setContinueButtonEnabled,
	clearInputStyling,
} from "controllers/mixins/wizard";

/**
 * Partner Wizard Controller
 * Handles step navigation, name validation, admin invitation, and completion flow
 */
export default class extends Controller {
	static targets = [
		...wizardTargets,
		"form",
		// Step 1: Name
		"nameInput",
		"nameMinLengthHint",
		"nameFeedback",
		"exactMatch",
		"exactMatchLink",
		"similarSection",
		"similarList",
		"nameAvailable",
		// Step 2: Location
		"addressFields",
		"serviceAreasContainer",
		"locationHint",
		"addressIncompleteHint",
		// Step 4: Contact
		"publicName",
		"publicEmail",
		"publicPhone",
		// Step 5: Admin
		"skipAdminCheckbox",
		"adminFields",
		"adminFirstName",
		"adminLastName",
		"adminEmail",
		"adminPhone",
		"adminEmailFeedback",
		"adminEmailAvailable",
		"adminEmailTaken",
		"adminEmailInvalid",
		// Step 6: Confirm
		"confirmPartnerName",
		"confirmAdminBox",
		"confirmAdminDetails",
	];

	static values = {
		...wizardValues,
		nameAvailable: { type: Boolean, default: false },
		adminEmailValid: { type: Boolean, default: false },
		adminSkipped: { type: Boolean, default: false },
		existingUserId: { type: Number, default: 0 },
	};

	connect() {
		this.checkNameDebounced = debounce(this.performNameCheck.bind(this), 400);
		this.checkAdminEmailDebounced = debounce(
			this.performAdminEmailCheck.bind(this),
			400,
		);
		updateWizardUI(this);
		this.updateContinueButton();
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

		// Auto-copy contact info when entering step 5 (Invite)
		if (step === 5) {
			this.copyFromContact();
		}

		// Update confirmation summary when entering step 6
		if (step === 6) {
			this.updateConfirmation();
		}
	}

	// Check if current step is valid (without showing errors)
	isCurrentStepValid() {
		if (this.currentStepValue === 1) {
			const name = this.hasNameInputTarget
				? this.nameInputTarget.value.trim()
				: "";
			return name.length >= 5 && this.nameAvailableValue;
		}
		if (this.currentStepValue === 2) {
			// Location step - need either address or service area
			return this.hasAddressOrServiceArea();
		}
		if (this.currentStepValue === 5) {
			// Admin step - valid if skipped OR if email is provided and valid
			if (this.adminSkippedValue) return true;
			const email = this.hasAdminEmailTarget
				? this.adminEmailTarget.value.trim()
				: "";
			// If no email entered, it's valid (optional)
			if (!email) return true;
			// If email entered, it must be valid format
			return this.adminEmailValidValue;
		}
		// Other steps have no required fields
		return true;
	}

	hasAddressOrServiceArea() {
		// Check if address has both street address AND postcode
		let hasValidAddress = false;
		let hasPartialAddress = false;
		if (this.hasAddressFieldsTarget) {
			const streetInput = this.addressFieldsTarget.querySelector(
				"input[name*='street_address']",
			);
			const postcodeInput = this.addressFieldsTarget.querySelector(
				"input[name*='postcode']",
			);
			const hasStreet = streetInput && streetInput.value.trim() !== "";
			const hasPostcode = postcodeInput && postcodeInput.value.trim() !== "";
			hasValidAddress = hasStreet && hasPostcode;
			// Partial address = has one but not both
			hasPartialAddress = (hasStreet || hasPostcode) && !hasValidAddress;
		}

		// Check if any service areas have a selected neighbourhood
		let hasServiceArea = false;
		if (this.hasServiceAreasContainerTarget) {
			const serviceAreas =
				this.serviceAreasContainerTarget.querySelectorAll(".nested-fields");
			// Check for visible service areas with a selected neighbourhood_id
			hasServiceArea = Array.from(serviceAreas).some((el) => {
				if (el.style.display === "none") return false;
				const neighbourhoodInput = el.querySelector(
					"input[name*='neighbourhood_id']",
				);
				return neighbourhoodInput && neighbourhoodInput.value.trim() !== "";
			});
		}

		// Valid if: (valid address OR service area) AND no partial address
		// If address is partially filled, block advancement regardless of service area
		const isValid = (hasValidAddress || hasServiceArea) && !hasPartialAddress;

		// Show/hide location hint (general requirement message)
		// Show when neither valid address nor service area
		if (this.hasLocationHintTarget) {
			const needsLocationHint =
				!hasValidAddress && !hasServiceArea && !hasPartialAddress;
			this.locationHintTarget.classList.toggle("hidden", !needsLocationHint);
		}

		// Show/hide address incomplete hint (specific to partial address)
		if (this.hasAddressIncompleteHintTarget) {
			this.addressIncompleteHintTarget.classList.toggle(
				"hidden",
				!hasPartialAddress,
			);
		}

		return isValid;
	}

	validateCurrentStep() {
		if (this.currentStepValue === 1) {
			const name = this.nameInputTarget.value.trim();
			if (name.length < 5 || !this.nameAvailableValue) {
				showInputError(this.nameInputTarget);
				return false;
			}
			clearInputError(this.nameInputTarget);
		}
		if (this.currentStepValue === 5 && !this.adminSkippedValue) {
			const email = this.hasAdminEmailTarget
				? this.adminEmailTarget.value.trim()
				: "";
			if (email && !this.adminEmailValidValue) {
				showInputError(this.adminEmailTarget);
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
	}

	// ==================
	// Step 1: Name validation
	// ==================
	checkName() {
		this.checkNameDebounced();
	}

	async performNameCheck() {
		const name = this.nameInputTarget.value.trim();

		// Show/hide min length hint
		if (this.hasNameMinLengthHintTarget) {
			this.nameMinLengthHintTarget.classList.toggle("hidden", name.length >= 5);
		}

		// Reset UI state
		this.nameFeedbackTarget.classList.add("hidden");
		this.exactMatchTarget.classList.add("hidden");
		this.similarSectionTarget.classList.add("hidden");
		this.nameAvailableTarget.classList.add("hidden");
		this.nameInputTarget.classList.remove("input-error", "input-success");
		this.nameAvailableValue = false;
		this.updateContinueButton();

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
				},
			);

			const data = await response.json();

			// Show feedback container
			this.nameFeedbackTarget.classList.remove("hidden");

			if (!data.name_available && data.exact_match) {
				// Exact match found - show warning
				this.exactMatchTarget.classList.remove("hidden");
				this.exactMatchLinkTarget.href = `/partners/${data.exact_match.id}/edit`;
				this.nameInputTarget.classList.add("input-error");
				this.nameAvailableValue = false;
			} else if (data.name_available) {
				// Name is available
				this.nameAvailableTarget.classList.remove("hidden");
				this.nameInputTarget.classList.add("input-success");
				this.nameAvailableValue = true;
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
							<span class="text-xs text-gray-600">View →</span>
						</a>
					`,
					)
					.join("");
			}
		} catch (error) {
			console.error("Error checking partner name:", error);
		} finally {
			this.updateContinueButton();
		}
	}

	// ==================
	// Step 5: Admin invitation
	// ==================
	toggleAdminFields() {
		const skipped = this.skipAdminCheckboxTarget.checked;
		this.adminSkippedValue = skipped;

		if (this.hasAdminFieldsTarget) {
			this.adminFieldsTarget.classList.toggle("hidden", skipped);
			this.adminFieldsTarget.classList.toggle("opacity-50", skipped);
			if (skipped) {
				// Disable inputs when skipped
				this.adminFieldsTarget
					.querySelectorAll("input")
					.forEach((input) => (input.disabled = true));
			} else {
				this.adminFieldsTarget
					.querySelectorAll("input")
					.forEach((input) => (input.disabled = false));
			}
		}

		this.updateContinueButton();
	}

	copyFromContact() {
		// Copy public contact info to admin fields
		if (this.hasPublicNameTarget && this.hasAdminFirstNameTarget) {
			// Try to split name into first/last
			const fullName = this.publicNameTarget.value.trim();
			const parts = fullName.split(" ");
			if (parts.length >= 2) {
				this.adminFirstNameTarget.value = parts[0];
				this.adminLastNameTarget.value = parts.slice(1).join(" ");
			} else if (parts.length === 1) {
				this.adminFirstNameTarget.value = parts[0];
			}
		}

		if (this.hasPublicEmailTarget && this.hasAdminEmailTarget) {
			this.adminEmailTarget.value = this.publicEmailTarget.value;
			// Trigger email validation
			this.checkAdminEmail();
		}

		if (this.hasPublicPhoneTarget && this.hasAdminPhoneTarget) {
			this.adminPhoneTarget.value = this.publicPhoneTarget.value;
		}
	}

	checkAdminEmail() {
		// Skip if triggered by browser autofill (field not focused)
		if (document.activeElement !== this.adminEmailTarget) return;
		this.checkAdminEmailDebounced();
	}

	async performAdminEmailCheck() {
		const email = this.adminEmailTarget.value.trim();

		// Reset UI state
		this.hideAdminEmailFeedback();
		clearInputStyling(this.adminEmailTarget);
		this.adminEmailValidValue = false;
		this.existingUserIdValue = 0;
		this.updateContinueButton();

		if (!email) {
			return;
		}

		// Basic client-side format validation
		if (!this.isValidEmailFormat(email)) {
			this.showAdminEmailInvalid();
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
				},
			);

			const data = await response.json();

			if (!data.valid) {
				this.showAdminEmailInvalid();
				return;
			}

			this.adminEmailValidValue = true;

			if (data.available) {
				this.showAdminEmailAvailable();
			} else {
				// User exists - we can still add them as admin
				this.existingUserIdValue = data.existing_user?.id || 0;
				this.showAdminEmailTaken();
			}
		} catch (error) {
			console.error("Error checking admin email:", error);
		} finally {
			this.updateContinueButton();
		}
	}

	isValidEmailFormat(email) {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
	}

	hideAdminEmailFeedback() {
		if (this.hasAdminEmailFeedbackTarget) {
			this.adminEmailFeedbackTarget.classList.add("hidden");
		}
		if (this.hasAdminEmailAvailableTarget) {
			this.adminEmailAvailableTarget.classList.add("hidden");
		}
		if (this.hasAdminEmailTakenTarget) {
			this.adminEmailTakenTarget.classList.add("hidden");
		}
		if (this.hasAdminEmailInvalidTarget) {
			this.adminEmailInvalidTarget.classList.add("hidden");
		}
	}

	showAdminEmailAvailable() {
		this.adminEmailTarget.classList.add("input-success");
		if (this.hasAdminEmailFeedbackTarget) {
			this.adminEmailFeedbackTarget.classList.remove("hidden");
		}
		if (this.hasAdminEmailAvailableTarget) {
			this.adminEmailAvailableTarget.classList.remove("hidden");
		}
	}

	showAdminEmailTaken() {
		// Not an error - we can add existing users as admins
		this.adminEmailTarget.classList.add("input-warning");
		if (this.hasAdminEmailFeedbackTarget) {
			this.adminEmailFeedbackTarget.classList.remove("hidden");
		}
		if (this.hasAdminEmailTakenTarget) {
			this.adminEmailTakenTarget.classList.remove("hidden");
		}
	}

	showAdminEmailInvalid() {
		this.adminEmailTarget.classList.add("input-error");
		if (this.hasAdminEmailFeedbackTarget) {
			this.adminEmailFeedbackTarget.classList.remove("hidden");
		}
		if (this.hasAdminEmailInvalidTarget) {
			this.adminEmailInvalidTarget.classList.remove("hidden");
		}
	}

	// ==================
	// Step 6: Confirmation
	// ==================
	updateConfirmation() {
		// Update partner name
		if (this.hasConfirmPartnerNameTarget && this.hasNameInputTarget) {
			this.confirmPartnerNameTarget.textContent =
				this.nameInputTarget.value.trim() || "-";
		}

		// Update admin info
		if (this.hasConfirmAdminBoxTarget) {
			const email = this.hasAdminEmailTarget
				? this.adminEmailTarget.value.trim()
				: "";

			if (email && !this.adminSkippedValue) {
				// Show admin box
				this.confirmAdminBoxTarget.classList.remove("hidden");

				// Build admin details text
				const firstName = this.hasAdminFirstNameTarget
					? this.adminFirstNameTarget.value.trim()
					: "";
				const lastName = this.hasAdminLastNameTarget
					? this.adminLastNameTarget.value.trim()
					: "";
				const name =
					firstName || lastName ? `${firstName} ${lastName}`.trim() : "";

				if (this.hasConfirmAdminDetailsTarget) {
					this.confirmAdminDetailsTarget.textContent = name
						? `${name} (${email})`
						: email;
				}
			} else {
				// Hide admin box
				this.confirmAdminBoxTarget.classList.add("hidden");
			}
		}
	}
}
