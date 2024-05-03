import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

// PartnerFormValidationController
export default class extends Controller {
	static targets = ["source"];

	connect() {
		const inputDebouncePeriod = 500; // ms
		const baseUrl = "/partners/lookup_name";

		const csrfToken = document
			.querySelector('meta[name="csrf-token"]')
			.getAttribute("content");

		const endpointHeaders = {
			method: "GET",
			headers: {
				Accept: "application/json",
				"Content-Type": "application/json",
				"X-CSRF-Token": csrfToken,
			},
		};

		const nameProblemFeedbackElement = document.getElementById(
			"partner-name-feedback"
		);

		const nameField = this.sourceTarget;
		const originalValue = nameField.value;

		this.inputFunction = _.debounce(() => {
			nameField.classList.remove("is-invalid");
			nameProblemFeedbackElement.style.display = "none";

			const nameValue = nameField.value;
			if (nameValue.length < 5 || nameValue === originalValue) {
				return;
			}

			const tryName = encodeURIComponent(nameValue);
			const url = `${baseUrl}?name=${tryName}`;

			fetch(url, endpointHeaders)
				.then((response) => response.json())
				.then((data) => {
					if (!data.name_available) {
						nameField.classList.add("is-invalid");
						nameProblemFeedbackElement.style.display = "block";
					}

					nameField.focus();
				});
		}, inputDebouncePeriod);
	}

	disconnect() {}

	checkInput(event) {
		this.inputFunction();
	}
}
