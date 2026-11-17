import { Controller } from "@hotwired/stimulus";

// Reloads the import status frame while its state says the calendar is busy.
export default class extends Controller {
	static targets = ["frame", "state", "announcer"];
	static values = { url: String, interval: Number, limit: Number };

	// Target callbacks run before connect(), so the clock starts here.
	initialize() {
		this.startedAt = Date.now();
	}

	disconnect() {
		clearTimeout(this.timer);
	}

	stateTargetConnected(state) {
		clearTimeout(this.timer);

		if ("poll" in state.dataset) {
			this.wasBusy = true;
			if (Date.now() - this.startedAt < this.limitValue) {
				this.timer = setTimeout(() => this.reload(), this.intervalValue);
			}
		} else if (this.wasBusy) {
			this.wasBusy = false;
			this.announcerTarget.textContent = state.dataset.announcement;
		}
	}

	reload() {
		if (this.frameTarget.src) this.frameTarget.reload();
		else this.frameTarget.src = this.urlValue;
	}

	// A redirect or 404 has no frame in it: keep the last strip and stop.
	missing(event) {
		event.preventDefault();
		clearTimeout(this.timer);
	}
}
