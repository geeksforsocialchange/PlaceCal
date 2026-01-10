import { Controller } from "@hotwired/stimulus";

// Save bar controller for partner form
// Handles tab-aware buttons, unsaved changes tracking, and navigation
export default class extends Controller {
	static targets = [
		"indicator",
		"indicatorDot",
		"indicatorText",
		"prevButton",
		"saveButton",
		"continueButton",
		"prevText",
		"continueText",
	];

	static values = {
		tabHashes: { type: Array, default: [] },
		settingsHash: { type: String, default: "settings" },
		previewHash: { type: String, default: "preview" },
	};

	connect() {
		this.dirty = false;
		this.form = this.element.closest("form");

		// Build tab hash list from actual tabs
		this.buildTabList();

		// Track form changes
		this.bindFormChanges();

		// Update buttons based on current tab
		this.updateButtons();

		// Listen for tab changes
		window.addEventListener("hashchange", () => this.updateButtons());

		// Also listen for radio changes (daisyUI tabs)
		document.querySelectorAll('input[name="partner_tabs"]').forEach((tab) => {
			tab.addEventListener("change", () => {
				setTimeout(() => this.updateButtons(), 10);
			});
		});
	}

	buildTabList() {
		const tabs = document.querySelectorAll(
			'input[name="partner_tabs"][data-hash]'
		);
		this.tabHashes = Array.from(tabs)
			.map((t) => t.dataset.hash)
			.filter(Boolean);
	}

	bindFormChanges() {
		if (!this.form) return;

		// Track all form inputs for changes
		const inputs = this.form.querySelectorAll(
			"input, textarea, select, [contenteditable]"
		);
		inputs.forEach((input) => {
			// Skip tab radio buttons and hidden system fields
			if (input.name === "partner_tabs") return;
			if (input.type === "hidden" && input.name === "_method") return;
			if (input.type === "hidden" && input.name === "authenticity_token")
				return;

			input.addEventListener("input", () => this.markDirty());
			input.addEventListener("change", () => this.markDirty());
		});

		// Track file inputs
		this.form.querySelectorAll('input[type="file"]').forEach((input) => {
			input.addEventListener("change", () => this.markDirty());
		});

		// Track checkboxes specifically
		this.form.querySelectorAll('input[type="checkbox"]').forEach((input) => {
			if (input.name === "partner_tabs") return;
			input.addEventListener("click", () => this.markDirty());
		});
	}

	markDirty() {
		if (this.dirty) return;
		this.dirty = true;
		this.updateIndicator();
		this.updateButtonTexts();
	}

	markClean() {
		this.dirty = false;
		this.updateIndicator();
		this.updateButtonTexts();
	}

	updateIndicator() {
		if (!this.hasIndicatorTarget) return;

		if (this.dirty) {
			this.indicatorTarget.classList.remove("opacity-0");
			this.indicatorTarget.classList.add("opacity-100");
			if (this.hasIndicatorDotTarget) {
				this.indicatorDotTarget.classList.add("animate-pulse");
			}
		} else {
			this.indicatorTarget.classList.remove("opacity-100");
			this.indicatorTarget.classList.add("opacity-0");
			if (this.hasIndicatorDotTarget) {
				this.indicatorDotTarget.classList.remove("animate-pulse");
			}
		}
	}

	updateButtonTexts() {
		if (this.hasPrevTextTarget) {
			this.prevTextTarget.textContent = this.dirty ? "Save & Back" : "Back";
		}
		if (this.hasContinueTextTarget) {
			this.continueTextTarget.textContent = this.dirty
				? "Save & Continue"
				: "Continue";
		}
	}

	getCurrentTabIndex() {
		const hash = window.location.hash.slice(1);
		if (hash && this.tabHashes.includes(hash)) {
			return this.tabHashes.indexOf(hash);
		}

		// Fall back to checked radio
		const checkedTab = document.querySelector(
			'input[name="partner_tabs"]:checked'
		);
		if (checkedTab && checkedTab.dataset.hash) {
			return this.tabHashes.indexOf(checkedTab.dataset.hash);
		}

		return 0;
	}

	getCurrentTabHash() {
		const index = this.getCurrentTabIndex();
		return this.tabHashes[index] || this.tabHashes[0];
	}

	isFirstTab() {
		return this.getCurrentTabIndex() === 0;
	}

	isLastTab() {
		return this.getCurrentTabIndex() === this.tabHashes.length - 1;
	}

	isSettingsTab() {
		return this.getCurrentTabHash() === this.settingsHashValue;
	}

	isPreviewTab() {
		return this.getCurrentTabHash() === this.previewHashValue;
	}

	updateButtons() {
		const isFirst = this.isFirstTab();
		const isSettings = this.isSettingsTab();
		const isPreview = this.isPreviewTab();

		// Previous button: hidden on first tab and settings tab
		if (this.hasPrevButtonTarget) {
			if (isFirst || isSettings) {
				this.prevButtonTarget.classList.add("hidden");
			} else {
				this.prevButtonTarget.classList.remove("hidden");
			}
		}

		// Continue button: hidden on settings tab and preview tab
		const continueHidden = isSettings || isPreview;
		if (this.hasContinueButtonTarget) {
			if (continueHidden) {
				this.continueButtonTarget.classList.add("hidden");
			} else {
				this.continueButtonTarget.classList.remove("hidden");
			}
		}

		// Save button: primary style when it's the main action (no Continue visible)
		if (this.hasSaveButtonTarget) {
			if (continueHidden) {
				// Make Save button primary
				this.saveButtonTarget.classList.remove(
					"bg-base-300",
					"hover:bg-base-content/20",
					"text-base-content",
					"border-base-300"
				);
				this.saveButtonTarget.classList.add(
					"bg-placecal-orange",
					"hover:bg-orange-600",
					"text-white",
					"border-placecal-orange"
				);
			} else {
				// Make Save button secondary
				this.saveButtonTarget.classList.remove(
					"bg-placecal-orange",
					"hover:bg-orange-600",
					"text-white",
					"border-placecal-orange"
				);
				this.saveButtonTarget.classList.add(
					"bg-base-300",
					"hover:bg-base-content/20",
					"text-base-content",
					"border-base-300"
				);
			}
		}

		// Update texts based on dirty state
		this.updateButtonTexts();
	}

	// Actions for buttons
	savePrevious(event) {
		if (this.dirty) {
			// Save and go to previous tab
			this.setNextTab(this.getCurrentTabIndex() - 1);
			// Form will submit normally
		} else {
			// Just navigate, no save needed
			event.preventDefault();
			this.goToPreviousTab();
		}
	}

	saveOnly(event) {
		// Stay on current tab after save
		this.setNextTab(this.getCurrentTabIndex());
		// Form submits normally
	}

	saveContinue(event) {
		if (this.dirty) {
			// Save and go to next tab
			this.setNextTab(this.getCurrentTabIndex() + 1);
			// Form will submit normally
		} else {
			// Just navigate, no save needed
			event.preventDefault();
			this.goToNextTab();
		}
	}

	setNextTab(index) {
		if (index >= 0 && index < this.tabHashes.length) {
			sessionStorage.setItem("partnerTabAfterSave", this.tabHashes[index]);
		}
	}

	goToPreviousTab() {
		const currentIndex = this.getCurrentTabIndex();
		if (currentIndex > 0) {
			this.goToTab(currentIndex - 1);
		}
	}

	goToNextTab() {
		const currentIndex = this.getCurrentTabIndex();
		if (currentIndex < this.tabHashes.length - 1) {
			this.goToTab(currentIndex + 1);
		}
	}

	goToTab(index) {
		const hash = this.tabHashes[index];
		if (!hash) return;

		// Find and check the tab
		const tab = document.querySelector(
			`input[name="partner_tabs"][data-hash="${hash}"]`
		);
		if (tab) {
			tab.checked = true;
			history.replaceState(null, null, `#${hash}`);
			this.updateButtons();
		}
	}
}
