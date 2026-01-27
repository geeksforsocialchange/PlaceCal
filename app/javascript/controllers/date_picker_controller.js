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
				// Get current URL params from hidden fields or URL
				const url = new URL(window.location.href);
				const period = url.searchParams.get("period") || "week";
				const sort = url.searchParams.get("sort") || "time";
				const repeating = url.searchParams.get("repeating") || "on";

				// Build the URL for the selected date
				const newUrl = `/events/${year}/${parseInt(month)}/${parseInt(
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
}
