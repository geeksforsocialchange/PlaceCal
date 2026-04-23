import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="partner-filter-component"
export default class extends Controller {
	static targets = [
		"form",
		"category",
		"categoryText",
		"categoryDropdown",
		"neighbourhood",
		"neighbourhoodText",
		"neighbourhoodDropdown",
	];

	/** Workaround for Stimulus's lack of typing
	 * @returns {{
	 * 		categoryDropdownTarget: HTMLElement | undefined,
	 * 		categoryTargets: HTMLInputElement[],
	 * 		categoryTextTarget: HTMLElement | undefined,
	 * 		formTarget: HTMLFormElement,
	 * 		neighbourhoodDropdownTarget: HTMLElement | undefined,
	 * 		neighbourhoodTargets: HTMLInputElement[],
	 * 		neighbourhoodTextTarget: HTMLElement | undefined,
	 * }} */
	get typedThis() {
		// @ts-ignore
		return this;
	}
	connect() {
		this.updateLabels();
	}

	submitCategory() {
		this.updateLabels();
		this.toggleDropdownHidden(this.typedThis.categoryDropdownTarget, true);
		this.submitForm();
	}

	submitNeighbourhood() {
		this.updateLabels();
		this.toggleDropdownHidden(this.typedThis.neighbourhoodDropdownTarget, true);
		this.submitForm();
	}

	resetCategory() {
		if (this.selectedCategory) this.selectedCategory.checked = false;
		this.toggleDropdownHidden(this.typedThis.categoryDropdownTarget, true);
		this.submitForm();
	}

	resetNeighbourhood() {
		if (this.selectedNeighbourhood) this.selectedNeighbourhood.checked = false;
		this.toggleDropdownHidden(this.typedThis.neighbourhoodDropdownTarget, true);
		this.submitForm();
	}

	toggleCategory() {
		this.toggleDropdownHidden(this.typedThis.categoryDropdownTarget);
		this.toggleDropdownHidden(this.typedThis.neighbourhoodDropdownTarget, true);
	}

	toggleNeighbourhood() {
		this.toggleDropdownHidden(this.typedThis.neighbourhoodDropdownTarget);
		this.toggleDropdownHidden(this.typedThis.categoryDropdownTarget, true);
	}

	/** Toggle dropdown hidden state. The optional `hidden` param will force a specific state
	 * @param {HTMLElement | undefined} dropdown
	 * @param {boolean | undefined} hidden
	 */
	toggleDropdownHidden(dropdown, hidden = undefined) {
		if (!dropdown) return;
		if (typeof hidden === "undefined")
			dropdown.classList.toggle("filters__dropdown--hidden");
		else dropdown.classList.toggle("filters__dropdown--hidden", hidden);
	}

	updateLabels() {
		// Find the associated label for each selected param and get the text contents
		// If params are selected, they show up instead of "Category" and "Neighbourhood" text
		if (this.typedThis.categoryTextTarget && this.selectedCategory?.labels)
			this.typedThis.categoryTextTarget.innerHTML =
				this.selectedCategory.labels[0].textContent;

		if (
			this.typedThis.neighbourhoodTextTarget &&
			this.selectedNeighbourhood?.labels
		)
			this.typedThis.neighbourhoodTextTarget.innerHTML =
				this.selectedNeighbourhood.labels[0].textContent;
	}

	submitForm() {
		this.typedThis.formTarget.requestSubmit();
	}

	get selectedCategory() {
		return this.typedThis.categoryTargets.find((r) => r.checked);
	}

	get selectedNeighbourhood() {
		return this.typedThis.neighbourhoodTargets.find((r) => r.checked);
	}
}
