import { Controller } from "@hotwired/stimulus";

// Gives each form control the hint, counter and required marker shown beside it, for screen readers
export default class extends Controller {
	static HINTS =
		"p.fieldset-label, [data-char-counter-target='counter'], [data-char-counter-target='display']";
	static CONTROLS =
		"input:not([type=hidden]):not(.tab):not(.tomselected), textarea, select:not(.tomselected)";
	static REQUIRED_MARKER = ".text-error[aria-hidden='true']";

	connect() {
		this.count = 0;
		this.element
			.querySelectorAll("fieldset.fieldset")
			.forEach((fieldset) => this.describe(fieldset));
		this.element
			.querySelectorAll(
				`label ${this.constructor.REQUIRED_MARKER}, legend ${this.constructor.REQUIRED_MARKER}`,
			)
			.forEach((marker) => {
				this.controlFor(marker.closest("label, legend"))?.setAttribute(
					"aria-required",
					"true",
				);
			});
	}

	describe(fieldset) {
		const controls = fieldset.querySelectorAll(this.constructor.CONTROLS);
		const hints = fieldset.querySelectorAll(this.constructor.HINTS);
		if (controls.length !== 1 || hints.length === 0) return;

		const ids = [...hints].map((hint) => {
			if (!hint.id) hint.id = `field-hint-${++this.count}`;
			return hint.id;
		});
		const existing = (controls[0].getAttribute("aria-describedby") || "")
			.split(" ")
			.filter(Boolean);
		controls[0].setAttribute(
			"aria-describedby",
			[...new Set([...existing, ...ids])].join(" "),
		);
	}

	controlFor(host) {
		if (host.tagName === "LABEL" && host.control) return host.control;

		const controls =
			host.closest("fieldset")?.querySelectorAll(this.constructor.CONTROLS) ||
			[];
		return controls.length === 1 ? controls[0] : null;
	}
}
