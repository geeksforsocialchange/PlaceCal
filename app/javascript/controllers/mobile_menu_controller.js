import { Controller } from "@hotwired/stimulus";

// Mobile Menu Controller - Toggle mobile navigation menu
// Used by the public site navigation component.
//
// The button is a disclosure: it owns the menu through aria-controls and must
// report its state, so aria-expanded is flipped alongside the class. The
// collapsed menu also carries `visibility: hidden` from its own utilities, so
// its links leave the tab order rather than being reachable off-screen.
export default class extends Controller {
	static targets = ["menu", "toggle"];

	toggle() {
		const expanded = this.menuTarget.classList.toggle("is-hidden") === false;

		if (this.hasToggleTarget) {
			this.toggleTarget.setAttribute("aria-expanded", String(expanded));
		}
	}
}
