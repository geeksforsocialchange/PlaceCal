import { Controller } from "@hotwired/stimulus";

const FOCUSABLE =
	'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])';

// Sits on a turbo frame whose filters live inside it: the reload replaces the control that had focus.
export default class extends Controller {
	static targets = ["summary"];
	static values = { status: String };

	remember(event) {
		this.lastFocused = this.selectorFor(event.target);
	}

	loaded() {
		this.restoreFocus();
		this.announce();
	}

	restoreFocus() {
		if (document.activeElement && document.activeElement !== document.body)
			return;

		const previous =
			this.lastFocused && this.element.querySelector(this.lastFocused);
		const target = previous ? this.visibleFocusable(previous) : null;
		if (target) target.focus({ preventScroll: true });
		else this.focusFrame();
	}

	// A focusable frame reads as one block to a screen reader, so it's focusable only while it has focus
	focusFrame() {
		this.element.setAttribute("tabindex", "-1");
		this.element.addEventListener(
			"blur",
			() => this.element.removeAttribute("tabindex"),
			{ once: true },
		);
		this.element.focus({ preventScroll: true });
	}

	announce() {
		const status = document.getElementById(this.statusValue);
		if (!status || !this.hasSummaryTarget) return;

		// Clearing first makes a screen reader repeat a summary that has not changed.
		status.textContent = "";
		requestAnimationFrame(() => {
			status.textContent = this.summaryTarget.textContent.trim();
		});
	}

	selectorFor(element) {
		if (element.id) return `#${CSS.escape(element.id)}`;
		if (element.name) {
			const name = `[name="${CSS.escape(element.name)}"]`;
			return element.type === "radio"
				? `${name}[value="${CSS.escape(element.value)}"]`
				: name;
		}
		const href = element.getAttribute("href");
		return href ? `a[href="${CSS.escape(href)}"]` : null;
	}

	// A control in a dropdown that rendered closed is hidden, so focus the nearest visible control around it, its toggle.
	visibleFocusable(element) {
		for (
			let node = element;
			node && node !== this.element;
			node = node.parentElement
		) {
			const candidates =
				node === element ? [element] : node.querySelectorAll(FOCUSABLE);
			const found = [...candidates].find(
				(candidate) => candidate.getClientRects().length > 0,
			);
			if (found) return found;
		}
		return null;
	}
}
