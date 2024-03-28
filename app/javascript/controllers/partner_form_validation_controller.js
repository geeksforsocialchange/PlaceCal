import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

// PartnerFormValidationController
export default class extends Controller {
	static targets = ["source"];

	connect() {
		const inputDebouncePeriod = 200;
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

		this.inputFunction = _.debounce(() => {
			this.sourceTarget.classList.remove("is-invalid");
			nameProblemFeedbackElement.style.display = "none";

			const nameValue = this.sourceTarget.value;
			if (nameValue.length < 1) {
				return;
			}

			const tryName = encodeURIComponent(nameValue);
			const url = `${baseUrl}?name=${tryName}`;

			fetch(url, endpointHeaders)
				.then((response) => response.json())
				.then((data) => {
					if (!data.name_available) {
						this.sourceTarget.classList.add("is-invalid");
						nameProblemFeedbackElement.style.display = "block";
					}

					this.sourceTarget.focus();
				});
		}, this.inputDebouncePeriod);

		this.sourceTarget.oninput = (event) => {
			this.inputFunction();
		};
	}

	disconnect() {}
}
