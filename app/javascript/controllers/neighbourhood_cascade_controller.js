import { Controller } from "@hotwired/stimulus";

// Cascading neighbourhood filter.
//
// Each geographic level is a CustomSelect that submits under the same
// `neighbourhood` name. When one changes, disable the others so only the level
// you touched is submitted — then the form's auto-submit applies just that one
// and the server re-renders the levels for the new selection.
export default class extends Controller {
	onChange(event) {
		for (const select of this.element.querySelectorAll(
			"select[name='neighbourhood']",
		)) {
			if (select !== event.target) select.disabled = true;
		}
	}
}
