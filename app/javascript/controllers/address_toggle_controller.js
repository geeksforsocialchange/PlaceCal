import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="address-toggle"
export default class extends Controller {
	static targets = ["toggle"];

	connect() {
		this.addressId = this.element.querySelector(
			"#partner_address_attributes_id"
		);
		this.toggleTarget.checked ? this.linkAddress() : this.delinkAddress();
	}

	click() {
		this.toggleTarget.checked ? this.linkAddress() : this.delinkAddress();
	}

	delinkAddress() {
		this.element.firstElementChild.removeChild(this.addressId);
	}

	linkAddress() {
		this.element.firstElementChild.appendChild(this.addressId);
	}
}
