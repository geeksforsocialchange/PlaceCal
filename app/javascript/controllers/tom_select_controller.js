import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

// Tom Select controller - vanilla JS replacement for Select2
// Supports single and multiple selections based on the select element's "multiple" attribute
export default class extends Controller {
	connect() {
		// Get placeholder from the first empty option
		const firstOption = this.element.querySelector('option[value=""]');
		const placeholder = firstOption ? firstOption.textContent.trim() : null;

		this.tomSelect = new TomSelect(this.element, {
			plugins: this.element.multiple ? ["remove_button"] : [],
			allowEmptyOption: false,
			closeAfterSelect: !this.element.multiple,
			placeholder: placeholder,
			hidePlaceholder: true,
		});

		// Store reference on element for external access
		this.element.tomSelectInstance = this.tomSelect;
	}

	disconnect() {
		if (this.tomSelect) {
			this.tomSelect.destroy();
			this.element.tomSelectInstance = null;
		}
	}

	// Action to clear the selection
	clear() {
		if (this.tomSelect) {
			this.tomSelect.clear();
		}
	}
}
