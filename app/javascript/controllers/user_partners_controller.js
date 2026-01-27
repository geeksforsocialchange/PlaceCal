import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

// User partners controller - Tom Select with partner removal confirmation
// Used for managing user's associated partners with permission checks
export default class extends Controller {
	static values = { permittedPartners: Array };

	connect() {
		const confirmRemove =
			"Removing this partner will remove this user from your view and you will no longer be able to access them.\n\nIf you want to keep the user in your view but still remove this partner from them, you'll need to make them an admin for another partner before removing this one.\n\nAre you sure you want to remove it?";
		const denyRemove =
			"You can only remove partners that you manage from a user.";

		this.tomSelect = new TomSelect(this.element, {
			plugins: ["remove_button"],
			allowEmptyOption: true,
			onItemRemove: (value) => {
				const partnerId = Number(value);
				const permittedValues = this.permittedPartnersValue.map(Number);
				const currentValues = this.tomSelect.items.map(Number);
				const selectedPermittedValues = permittedValues.filter((x) =>
					currentValues.includes(x),
				);

				// Check if user is trying to remove a non-permitted partner
				if (!permittedValues.includes(partnerId)) {
					alert(denyRemove);
					// Re-add the item since we're blocking removal
					this.tomSelect.addItem(value, true);
					return false;
				}

				// Check if this is the last permitted partner
				if (
					selectedPermittedValues.length <= 1 &&
					permittedValues.includes(partnerId)
				) {
					if (!confirm(confirmRemove)) {
						// Re-add the item since user cancelled
						this.tomSelect.addItem(value, true);
						return false;
					}
				}

				return true;
			},
		});
	}

	disconnect() {
		if (this.tomSelect) {
			this.tomSelect.destroy();
		}
	}
}
