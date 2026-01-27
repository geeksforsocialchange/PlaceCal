import { Controller } from "@hotwired/stimulus";

// Date Picker Controller - Toggle date picker dropdown and navigate on date selection
export default class extends Controller {
	static targets = ["dropdown", "input"];

	toggle(event) {
		event.preventDefault();
		this.dropdownTargets.forEach((dropdown) => {
			dropdown.classList.toggle("breadcrumb__date-picker-dropdown--hidden");
		});
	}

	submit() {
		if (this.hasInputTarget) {
			const date = this.inputTarget.value;
			if (date) {
				const [year, month, day] = date.split("-");
				// Get current filter values from hidden fields in the form (most accurate)
				const form = this.inputTarget.closest("form");
				const period =
					form?.querySelector('input[name="period"]')?.value || "week";
				const sort = form?.querySelector('input[name="sort"]')?.value || "time";
				const repeating =
					form?.querySelector('input[name="repeating"]')?.value || "on";

				// Build the URL for the selected date
				// Determine base path from existing paginator links or current URL
				const basePath = this.getBasePath();
				const newUrl = `${basePath}/${year}/${parseInt(month)}/${parseInt(
					day
				)}?period=${period}&sort=${sort}&repeating=${repeating}#paginator`;

				// Navigate using Turbo with frame targeting
				const frame = document.querySelector("turbo-frame#events-browser");
				if (frame) {
					frame.src = newUrl;
				} else {
					// Fallback to full page navigation
					window.location.href = newUrl;
				}

				// Close the dropdown
				this.dropdownTargets.forEach((dropdown) => {
					dropdown.classList.add("breadcrumb__date-picker-dropdown--hidden");
				});
			}
		}
	}

	getBasePath() {
		// Try to extract base path from an existing paginator link
		const paginatorLink = document.querySelector(".paginator__buttons a[href]");
		if (paginatorLink) {
			const href = paginatorLink.getAttribute("href");
			// Extract path before the year (e.g., /partners/slug/events or /events)
			const match = href.match(/^(.*\/events)\/\d{4}/);
			if (match) {
				return match[1];
			}
		}

		// Fallback: check current URL path
		const path = window.location.pathname;
		// If we're on a partner page, construct partner events path
		const partnerMatch = path.match(/^(\/partners\/[^/]+)/);
		if (partnerMatch) {
			return `${partnerMatch[1]}/events`;
		}

		// Default to /events
		return "/events";
	}
}
