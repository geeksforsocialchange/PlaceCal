import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

// Tom Select controller - vanilla JS replacement for Select2
// Supports single and multiple selections based on the select element's "multiple" attribute
export default class extends Controller {
	connect() {
		this.tomSelect = new TomSelect(this.element, {
			plugins: this.element.multiple ? ["remove_button"] : [],
			allowEmptyOption: true,
			closeAfterSelect: !this.element.multiple,
		});
	}

	disconnect() {
		if (this.tomSelect) {
			this.tomSelect.destroy();
		}
	}
}
