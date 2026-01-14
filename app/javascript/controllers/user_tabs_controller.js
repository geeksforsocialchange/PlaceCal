import { Controller } from "@hotwired/stimulus";

// User form tabs controller
// Handles hash navigation for the user edit form
export default class extends Controller {
	static targets = ["tab", "panel"];

	connect() {
		this.selectTabFromHash();

		this.boundHashChange = this.handleHashChange.bind(this);
		window.addEventListener("hashchange", this.boundHashChange);

		this.tabTargets.forEach((tab) => {
			tab.addEventListener("change", this.handleTabChange.bind(this));
		});

		this.restoreTabAfterSave();
	}

	disconnect() {
		window.removeEventListener("hashchange", this.boundHashChange);
	}

	handleHashChange() {
		this.selectTabFromHash();
	}

	selectTabFromHash() {
		const hash = window.location.hash.slice(1);
		if (!hash) return;

		const tab = this.tabTargets.find((t) => t.dataset.hash === hash);
		if (tab && !tab.checked) {
			tab.checked = true;
		}
	}

	handleTabChange(event) {
		const hash = event.target.dataset.hash;
		if (hash) {
			history.replaceState(null, null, `#${hash}`);
		}
	}

	restoreTabAfterSave() {
		const savedHash = sessionStorage.getItem("userTabAfterSave");
		if (savedHash) {
			sessionStorage.removeItem("userTabAfterSave");
			const tab = this.tabTargets.find((t) => t.dataset.hash === savedHash);
			if (tab) {
				tab.checked = true;
				history.replaceState(null, null, `#${savedHash}`);
			}
		}
	}

	// Called by form action when user is about to save
	prepareNextTab() {
		const currentTab = this.tabTargets.find((t) => t.checked);
		if (!currentTab) return;

		const currentIndex = this.tabTargets.indexOf(currentTab);
		const nextTab = this.tabTargets[currentIndex + 1];

		if (nextTab && nextTab.dataset.hash) {
			sessionStorage.setItem("userTabAfterSave", nextTab.dataset.hash);
		}
	}
}
