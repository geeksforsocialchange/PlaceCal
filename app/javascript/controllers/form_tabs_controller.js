import { Controller } from "@hotwired/stimulus";

// Generic form tabs controller
// Handles hash navigation and tab restoration for multi-tab forms
// Used by partner, calendar, site, and user edit forms
export default class extends Controller {
	static targets = ["tab", "panel"];

	static values = {
		storageKey: { type: String, default: "formTabAfterSave" },
	};

	connect() {
		// Select tab from URL hash on load
		this.selectTabFromHash();

		// Listen for hash changes
		this.boundHashChange = this.handleHashChange.bind(this);
		window.addEventListener("hashchange", this.boundHashChange);

		// Listen for tab changes to update URL hash
		this.tabTargets.forEach((tab) => {
			tab.addEventListener("change", this.handleTabChange.bind(this));
		});

		// Check for saved tab after form submission
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
		const savedHash = sessionStorage.getItem(this.storageKeyValue);
		if (savedHash) {
			sessionStorage.removeItem(this.storageKeyValue);
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
			sessionStorage.setItem(this.storageKeyValue, nextTab.dataset.hash);
		}
	}
}
