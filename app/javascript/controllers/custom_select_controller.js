import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["trigger", "panel", "option", "hiddenSelect", "arrow"];
	static values = { open: { type: Boolean, default: false } };

	connect() {
		this.outsideClickHandler = this.closeOnOutsideClick.bind(this);
		this.keydownHandler = this.handleKeydown.bind(this);
		document.addEventListener("click", this.outsideClickHandler);
		document.addEventListener("keydown", this.keydownHandler);
	}

	disconnect() {
		document.removeEventListener("click", this.outsideClickHandler);
		document.removeEventListener("keydown", this.keydownHandler);
	}

	toggle(event) {
		event.stopPropagation();
		this.openValue = !this.openValue;
	}

	openValueChanged() {
		if (this.openValue) {
			this.panelTarget.style.display = "block";
			this.arrowTarget.style.transform = "rotate(180deg)";
		} else {
			this.panelTarget.style.display = "none";
			this.arrowTarget.style.transform = "";
		}
	}

	select(event) {
		const value = event.currentTarget.dataset.value;
		const label = event.currentTarget.dataset.label;

		this.hiddenSelectTarget.value = value;
		this.triggerTarget.querySelector("[data-role='label']").textContent = label;

		this.optionTargets.forEach((opt) => {
			opt.dataset.selected = opt.dataset.value === value ? "true" : "false";
		});

		this.openValue = false;

		this.hiddenSelectTarget.dispatchEvent(
			new Event("change", { bubbles: true }),
		);
	}

	closeOnOutsideClick(event) {
		if (!this.element.contains(event.target)) {
			this.openValue = false;
		}
	}

	handleKeydown(event) {
		if (!this.openValue) return;
		if (event.key === "Escape") {
			this.openValue = false;
		}
	}
}
