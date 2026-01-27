import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class extends Controller {
	static values = { permittedTags: [String] };

	connect() {
		this.tomSelect = new TomSelect(this.element, {
			plugins: ["remove_button"],
			allowEmptyOption: true,
			onItemRemove: (value) => {
				const permittedValues = this.permittedTagsValue.map(Number);
				const numValue = Number(value);

				// Get current selected values
				const selectedValues = this.tomSelect.items.map(Number);

				// Count how many permitted values are selected (excluding the one being removed)
				const selectedPermittedValues = permittedValues.filter((x) =>
					selectedValues.includes(x),
				);

				if (
					selectedPermittedValues.length <= 1 &&
					permittedValues.includes(numValue)
				) {
					if (
						!confirm(
							"Removing this tag will remove this partner from your partnership and you will no longer be able to access them, or any users that are partner admins for this partner, if they are not partner admins for anyone else in your partnership.\n\n Are you sure you want to remove it?",
						)
					) {
						// Re-add the item since we can't prevent the removal
						this.tomSelect.addItem(value, true);
						return;
					}
				}

				if (!permittedValues.includes(numValue)) {
					alert(
						"You can only remove partnership tags for partnerships that you manage.",
					);
					// Re-add the item since we can't prevent the removal
					this.tomSelect.addItem(value, true);
				}
			},
		});
	}

	disconnect() {
		if (this.tomSelect) {
			this.tomSelect.destroy();
		}
	}
}
