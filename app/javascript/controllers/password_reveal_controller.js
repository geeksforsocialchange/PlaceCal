import { Controller } from "@hotwired/stimulus";

// Toggles a password field between hidden and visible text
export default class extends Controller {
	static targets = ["input", "button", "showIcon", "hideIcon", "status"];
	static values = {
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
		this.render("text", this.hideLabelValue, this.shownValue);
	}

	conceal() {
		if (this.inputTarget.type === "password") return;
		this.render("password", this.showLabelValue, this.hiddenValue);
	}

	render(type, label, status) {
		this.inputTarget.type = type;
		this.showIconTarget.hidden = type === "text";
		this.hideIconTarget.hidden = type === "password";
		this.buttonTarget.setAttribute("aria-label", label);
		this.statusTarget.textContent = status;
	}
}
