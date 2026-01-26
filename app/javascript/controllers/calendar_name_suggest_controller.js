import { Controller } from "@hotwired/stimulus";

/**
 * Suggests calendar name based on partner selection.
 * When a partner is selected and the name field is empty,
 * shows a suggestion that can be applied with one click.
 */
export default class extends Controller {
	static targets = ["partner", "name", "suggestion"];
	static values = {
		suffix: { type: String, default: " Calendar" },
	};

	connect() {
		// Check initial state after a short delay to allow tom-select to initialize
		setTimeout(() => this.updateSuggestion(), 100);
	}

	partnerChanged() {
		this.updateSuggestion();
	}

	updateSuggestion() {
		if (!this.hasPartnerTarget || !this.hasNameTarget) return;

		const partnerSelect = this.partnerTarget;
		const nameInput = this.nameTarget;

		// Get the tom-select instance if available, otherwise use native select
		const tomSelect = partnerSelect.tomselect;
		let partnerName = "";

		if (tomSelect) {
			const selectedItem = tomSelect.getItem(tomSelect.getValue());
			if (selectedItem) {
				partnerName = selectedItem.textContent.trim();
			}
		} else if (
			partnerSelect.selectedOptions &&
			partnerSelect.selectedOptions[0]
		) {
			const selectedOption = partnerSelect.selectedOptions[0];
			if (selectedOption.value) {
				partnerName = selectedOption.text;
			}
		}

		// Only show suggestion if name is empty and partner is selected
		if (partnerName && !nameInput.value.trim()) {
			const suggestedName = partnerName + this.suffixValue;

			if (this.hasSuggestionTarget) {
				// Update the suggestion text
				this.suggestionTarget.dataset.suggestedName = suggestedName;
				this.suggestionTarget.classList.remove("hidden");
			}
		} else {
			if (this.hasSuggestionTarget) {
				this.suggestionTarget.classList.add("hidden");
			}
		}
	}

	applySuggestion() {
		if (!this.hasNameTarget || !this.hasSuggestionTarget) return;

		const suggestedName = this.suggestionTarget.dataset.suggestedName;
		if (suggestedName) {
			this.nameTarget.value = suggestedName;
			this.suggestionTarget.classList.add("hidden");

			// Trigger change event so other controllers know the field changed
			this.nameTarget.dispatchEvent(new Event("change", { bubbles: true }));
		}
	}
}
