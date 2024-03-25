import { Controller } from "@hotwired/stimulus";

console.log("hey there?");

// PartnerFormValidationController
export default class extends Controller {
	static targets = ["source"];

	connect() {
		console.log("PartnerFormValidationController connected");
		console.log("source=", this.sourceTarget);

		this.sourceTarget.oninput = (event) => {
			this.sourceTarget.disabled = true;
			this.sourceTarget.classList.remove("is-invalid");

			const csrfToken = document
				.querySelector('meta[name="csrf-token"]')
				.getAttribute("content");

			let try_name = encodeURIComponent(this.sourceTarget.value);
			const url = `/partners/lookup_name?name=${try_name}`;
			console.log("url=", url);

			const payload = {
				method: "GET",
				headers: {
					Accept: "application/json",
					"Content-Type": "application/json",
					"X-CSRF-Token": csrfToken,
				},
			};

			fetch(url, payload)
				.then((response) => response.json())
				.then((data) => {
					if (!data.name_available) {
						this.sourceTarget.classList.add("is-invalid");
					}

					console.log("data=", data);
					this.sourceTarget.disabled = false;
					this.sourceTarget.focus();
				});
		};
	}

	disconnect() {}
}
