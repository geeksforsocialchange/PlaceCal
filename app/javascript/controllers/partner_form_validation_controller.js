import { Controller } from "@hotwired/stimulus";

// PartnerFormValidationController
export default class extends Controller {
	static targets = ["source"];

	connect() {
		console.log("PartnerFormValidationController.connect");

		//this.inputDebouncePeriod = 200;
		this.baseUrl = "/partners/lookup_name";

		const csrfToken = document
			.querySelector('meta[name="csrf-token"]')
			.getAttribute("content");

		this.endpointHeaders = {
			method: "GET",
			headers: {
				Accept: "application/json",
				"Content-Type": "application/json",
				"X-CSRF-Token": csrfToken,
			},
		};

		this.nameProblemFeedbackElement = document.getElementById(
			"partner-name-feedback"
		);

		this.nameField = this.sourceTarget;
		this.originalValue = this.nameField.value;
	}

	disconnect() {}

	checkInput(event) {
		console.log("PartnerFormValidationController.checkInput");

		this.nameField.classList.remove("is-invalid");
		this.nameProblemFeedbackElement.style.display = "none";

		const nameValue = this.sourceTarget.value;
		if (nameValue.length < 5 || nameValue === this.originalValue) {
			return;
		}

		const tryName = encodeURIComponent(nameValue);
		const url = `${this.baseUrl}?name=${tryName}`;

		fetch(url, this.endpointHeaders)
			.then((response) => response.json())
			.then((data) => {
				if (!data.name_available) {
					this.nameField.classList.add("is-invalid");
					this.nameProblemFeedbackElement.style.display = "block";
				}

				this.nameField.focus();
			});
	}
}
