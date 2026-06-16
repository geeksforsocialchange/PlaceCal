import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["trigger", "panel", "option", "hiddenSelect", "arrow"];
	static values = { open: { type: Boolean, default: false } };

	connect() {
		this.outsideClickHandler = this.closeOnOutsideClick.bind(this);
		this.keydownHandler = this.handleKeydown.bind(this);
		document.addEventListener("click", this.outsideClickHandler);
		document.addEventListener("keydown", this.keydownHandler);
		// Signal readiness so system specs can wait for connect() before
		// clicking the trigger. The toggle action is silently dropped if the
		// trigger is clicked before JS boots (notably in CI).
		this.element.dataset.customSelectConnected = "true";
	}

	disconnect() {
		document.removeEventListener("click", this.outsideClickHandler);
		document.removeEventListener("keydown", this.keydownHandler);
		delete this.element.dataset.customSelectConnected;
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

		// Apply the filter immediately on selection — no need to press Filter.
		this.element.closest("form")?.requestSubmit();
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
