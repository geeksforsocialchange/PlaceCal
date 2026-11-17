import { Controller } from "@hotwired/stimulus";

// Refreshes the page's counts and its frame each time the table inside it refreshes itself.
export default class extends Controller {
	static targets = ["frame"];
	static values = { url: String };

	async update() {
		this.reloadFrame();
		try {
			const response = await fetch(this.urlValue, {
				headers: { Accept: "application/json" },
			});
			if (!response.ok) return;
			const counts = await response.json();
			this.element.querySelectorAll("[data-live-count]").forEach((element) => {
				const count = counts[element.dataset.liveCount];
				if (count !== undefined) element.textContent = count;
			});
		} catch {
			// A failed tick keeps the last counts; the next tick tries again
		}
	}

	reloadFrame() {
		if (!this.hasFrameTarget) return;
		if (this.frameTarget.src) this.frameTarget.reload();
		else this.frameTarget.src = window.location.pathname;
	}
}
