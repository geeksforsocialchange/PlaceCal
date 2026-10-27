import { Controller } from "@hotwired/stimulus";

// Toggles a password field between hidden and visible text
export default class extends Controller {
	static targets = ["input", "button", "status"];
	static values = {
		show: String,
		hide: String,
		showLabel: String,
		hideLabel: String,
		shown: String,
		hidden: String,
	};

	connect() {
		this.form = this.element.closest("form");
		this.hideOnSubmit = () => this.conceal();
		this.form?.addEventListener("submit", this.hideOnSubmit);
		// Without JavaScript the button would do nothing, so it starts hidden
		this.buttonTarget.hidden = false;
	}

	disconnect() {
		this.form?.removeEventListener("submit", this.hideOnSubmit);
	}

	toggle() {
		if (this.inputTarget.type === "password") {
			this.reveal();
		} else {
			this.conceal();
		}
	}

	reveal() {
		this.render("text", this.hideValue, this.hideLabelValue, this.shownValue);
	}

	conceal() {
		if (this.inputTarget.type === "password") return;
		this.render(
			"password",
			this.showValue,
			this.showLabelValue,
			this.hiddenValue,
		);
	}

	render(type, text, label, status) {
		this.inputTarget.type = type;
		this.buttonTarget.textContent = text;
		this.buttonTarget.setAttribute("aria-label", label);
		this.statusTarget.textContent = status;
	}
}
