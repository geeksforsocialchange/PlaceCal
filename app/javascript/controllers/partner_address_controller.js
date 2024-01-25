import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = {
		partnerId: String,
	};

	static targets = ["addressInfoArea"];

	static addressFieldIds = [
		"partner_address_attributes_street_address",
		"partner_address_attributes_street_address2",
		"partner_address_attributes_street_address3",
		"partner_address_attributes_city",
		"partner_address_attributes_postcode",
	];

	connect() {}

	disconnect() {}

	do_clear_address(event) {
		console.log("do_clear_address");

		event.preventDefault();
		console.log("do_clear_address");

		if (!confirm("Please confirm you want to clear this partners address")) {
			return;
		}

		const csrfToken = document
			.querySelector('meta[name="csrf-token"]')
			.getAttribute("content");

		const url = `/partners/${this.partnerIdValue}/clear_address`;

		const payload = {
			method: "DELETE",
			headers: {
				Accept: "application/json",
				"Content-Type": "application/json",
				"X-CSRF-Token": csrfToken,
			},
			body: "",
		};

		fetch(url, payload)
			.then((response) => response.json())
			.then((data) => {
				this.constructor.addressFieldIds.forEach((id) => {
					let node = document.getElementById(id);
					node.value = "";
					node.classList.remove("is-valid");
				});

				this.addressInfoAreaTarget.innerHTML =
					"<p>Address has been cleared</p>";
			});
	}
}
