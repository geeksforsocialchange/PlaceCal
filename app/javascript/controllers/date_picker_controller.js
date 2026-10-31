import { Controller } from "@hotwired/stimulus";

// Date Picker Controller - Navigate on date selection
export default class extends Controller {
	static targets = ["input", "period", "sort", "repeating"];

	open(event) {
		event.preventDefault();
		if (!this.hasInputTarget) return;

		// showPicker() needs a live user gesture; a re-dispatched click (a
		// proxy, a test driver) loses it, so fall back to the native control.
		try {
			this.inputTarget.showPicker();
		} catch {
			this.inputTarget.focus();
			this.inputTarget.click();
		}
	}

	submit() {
		if (!this.hasInputTarget) return;

		const date = this.inputTarget.value;
		if (!date) return;

		const [year, month, day] = date.split("-");
		const period = this.hasPeriodTarget ? this.periodTarget.value : "week";
		const sort = this.hasSortTarget ? this.sortTarget.value : "time";
		const repeating = this.hasRepeatingTarget
			? this.repeatingTarget.value
			: "on";

		const basePath = this.getBasePath();
		const newUrl = `${basePath}/${year}/${parseInt(month)}/${parseInt(
			day,
		)}?period=${period}&sort=${sort}&repeating=${repeating}#paginator`;

		const frame = document.querySelector("turbo-frame#events-browser");
		if (frame) {
			frame.src = newUrl;
		} else {
			window.location.href = newUrl;
		}
	}

	getBasePath() {
		const paginatorLink = document.querySelector(
			'[data-controller~="paginator"] a[href]',
		);
		if (paginatorLink) {
			const href = paginatorLink.getAttribute("href");
			const match = href.match(/^(.*\/events)\/\d{4}/);
			if (match) return match[1];
		}

		const path = window.location.pathname;
		const partnerMatch = path.match(/^(\/partners\/[^/]+)/);
		if (partnerMatch) return `${partnerMatch[1]}/events`;

		return "/events";
	}
}
