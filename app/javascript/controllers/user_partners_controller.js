import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { permittedPartners: [String] };

	connect() {
		const confirmRemove =
			"Removing this partner will remove this user from your view and you will no longer be able to access them.\n\nIf you want to keep the user in your view but still remove this partner from them, you'll need to make them an admin for another partner before removing this one.\n\nAre you sure you want to remove it?";
		const denyRemove =
			"You can only remove partners that you manage from a user.";

		const getSelectValues = (select) => {
			return [...(select && select.options)].reduce((accumulator, option) => {
				if (option.selected) {
					return [...accumulator, Number(option.value || option.text)];
				}
				return accumulator;
			}, []);
		};

		$(this.element).select2();

		$(this.element).on("select2:unselecting", (event) => {
			const selectedValues = getSelectValues(this.element);
			const permittedValues = this.permittedPartnersValue;
			const selectedPermittedValues = permittedValues.filter((x) =>
				selectedValues.includes(x)
			);

			if (
				selectedPermittedValues.length <= 1 &&
				permittedValues.includes(Number(event.params.args.data.id))
			) {
				if (!confirm(confirmRemove)) {
					event.preventDefault();
				}
			}

			if (!permittedValues.includes(Number(event.params.args.data.id))) {
				alert(denyRemove);
				event.preventDefault();
			}
		});

		$(this.element).select2("close");
	}

	disconnect() {
		$(this.element).select2("destroy");
	}
}
