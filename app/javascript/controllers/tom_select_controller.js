import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

// Tom Select controller - vanilla JS replacement for Select2
// Supports single and multiple selections based on the select element's "multiple" attribute
export default class extends Controller {
	static values = { showAll: Boolean };

	connect() {
		// Get placeholder from the first empty option
		const firstOption = this.element.querySelector('option[value=""]');
		const placeholder = firstOption ? firstOption.textContent.trim() : null;

		// Get aria-label from original element for accessibility
		const ariaLabel = this.element.getAttribute("aria-label");

		this.tomSelect = new TomSelect(this.element, {
			plugins: this.element.multiple ? ["remove_button"] : [],
			allowEmptyOption: false,
			closeAfterSelect: !this.element.multiple,
			placeholder: placeholder,
			hidePlaceholder: true,
			// Opening on focus made screen readers announce an option, not the field
			openOnFocus: false,
			// Tom Select otherwise lists only the first 50 options until you type
			...(this.showAllValue && { maxOptions: null }),
		});

		// Copy aria-label to the generated control input for accessibility
		if (ariaLabel && this.tomSelect.control_input) {
			this.tomSelect.control_input.setAttribute("aria-label", ariaLabel);
		}

		// With openOnFocus off, a click only focuses, so open the list ourselves
		this.tomSelect.control.addEventListener("click", () => {
			if (!this.tomSelect.isOpen) this.tomSelect.open();
		});

		for (const attr of ["aria-describedby", "aria-required"]) {
			const value = this.element.getAttribute(attr);
			if (value) this.tomSelect.control_input.setAttribute(attr, value);
		}

		if (!this.element.multiple) this.announceValue();

		// Store reference on element for external access
		this.element.tomSelectInstance = this.tomSelect;
	}

	disconnect() {
		if (this.tomSelect) {
			this.tomSelect.destroy();
			this.element.tomSelectInstance = null;
		}
	}

	// The chosen item sits outside the combobox input, so add its text to the input's name
	announceValue() {
		const input = this.tomSelect.control_input;
		const value = document.createElement("span");
		value.id = `${input.id}-value`;
		value.hidden = true;
		this.tomSelect.wrapper.append(value);

		const label = input.getAttribute("aria-labelledby") || input.id;
		input.setAttribute("aria-labelledby", `${label} ${value.id}`);

		const update = () => {
			value.textContent = this.tomSelect.items
				.map(
					(v) =>
						this.tomSelect.options[v]?.[this.tomSelect.settings.labelField],
				)
				.join(", ");
		};
		update();
		this.tomSelect.on("change", update);
	}

	// Action to clear the selection
	clear() {
		if (this.tomSelect) {
			this.tomSelect.clear();
		}
	}
}
