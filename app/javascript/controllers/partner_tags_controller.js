import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { permittedTags: [String] };

	connect() {
		console.log("PartnerTagsController.connect");

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
			const permittedValues = this.permittedTagsValue;

			const selectedPermittedValues = permittedValues.filter((x) =>
				selectedValues.includes(x)
			);

			if (
				selectedPermittedValues.length <= 1 &&
				permittedValues.includes(Number(event.params.args.data.id))
			) {
				if (
					!confirm(
						"Removing this tag will remove this partner from your partnership and you will no longer be able to access them, or any users that are partner admins for this partner, if they are not partner admins for anyone else in your partnership.\n\n Are you sure you want to remove it?"
					)
				) {
					event.preventDefault();
				}
			}

			if (!permittedValues.includes(Number(event.params.args.data.id))) {
				alert(
					"You can only remove partnership tags for partnerships that you manage."
				);
				event.preventDefault();
			}
		});

		$(this.element).select2("close");
	}

	disconnect() {
		$(this.element).select2("destroy");
	}
}
