import { Controller } from "@hotwired/stimulus";
import {
	setupFormTracking,
	teardownFormTracking,
	markDirty,
	markClean,
	isDirty,
	updateIndicator,
} from "controllers/mixins/form_tracking";

// Save bar controller for multi-step forms
// Handles tab-aware buttons, unsaved changes tracking, and navigation
// Works with partner, site, and calendar forms
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
		tabName: { type: String, default: "partner_tabs" },
		settingsHash: { type: String, default: "settings" },
		previewHash: { type: String, default: "preview" },
		storageKey: { type: String, default: "tabAfterSave" },
	};

	connect() {
		this.form = this.element.closest("form");

		// Setup shared form tracking with initial value tracking (for revert detection)
		setupFormTracking(this, {
			tabName: this.tabNameValue,
			form: this.form,
			trackInitialValues: true,
			onDirtyChange: (dirty) => this.handleDirtyChange(dirty),
		});

		// Build tab hash list from actual tabs
		this.buildTabList();

		// Update buttons based on current tab
		this.updateButtons();

		// Listen for tab changes
		window.addEventListener("hashchange", () => this.updateButtons());

		// Also listen for radio changes (daisyUI tabs) - prompt if unsaved
		document
			.querySelectorAll(`input[name="${this.tabNameValue}"]`)
			.forEach((tab) => {
				tab.addEventListener("click", (event) => {
					if (isDirty(this) && !this.confirmingTabChange) {
						const confirmed = confirm(
							"You have unsaved changes. Are you sure you want to switch tabs?",
						);
						if (!confirmed) {
							event.preventDefault();
							event.stopPropagation();
							return;
						}
					}
					setTimeout(() => this.updateButtons(), 10);
				});
			});
	}

	disconnect() {
		teardownFormTracking(this);
	}

	get dirty() {
		return isDirty(this);
	}

	handleDirtyChange() {
		this.updateIndicatorDisplay();
		this.updateButtonTexts();
		this.updateSaveButtonStyle();
	}

	markDirty() {
		markDirty(this);
	}

	markClean() {
		markClean(this);
	}

	buildTabList() {
		const tabs = document.querySelectorAll(
			`input[name="${this.tabNameValue}"][data-hash]`,
		);
		this.tabHashes = Array.from(tabs)
			.map((t) => t.dataset.hash)
			.filter(Boolean);
	}

	updateIndicatorDisplay() {
		if (this.hasIndicatorTarget) {
			updateIndicator(this.indicatorTarget, isDirty(this));
		}
	}

	updateButtonTexts() {
		const dirty = isDirty(this);
		if (this.hasPrevTextTarget) {
			this.prevTextTarget.textContent = dirty ? "Save & Back" : "Back";
		}
		if (this.hasContinueTextTarget) {
			this.continueTextTarget.textContent = dirty
				? "Save & Continue"
				: "Continue";
		}
	}

	updateSaveButtonStyle() {
		if (!this.hasSaveButtonTarget) return;

		const dirty = isDirty(this);
		const isMainAction = this.isSaveButtonMainAction();

		if (dirty) {
			// Active state - orange button
			this.saveButtonTarget.classList.remove(
				"bg-base-300",
				"hover:bg-base-content/20",
				"text-base-content",
				"border-base-300",
				"opacity-50",
			);
			this.saveButtonTarget.classList.add(
				"bg-placecal-orange",
				"hover:bg-orange-600",
				"text-white",
				"border-placecal-orange",
			);
		} else if (isMainAction) {
			// Clean state but main action - looks disabled but clickable
			this.saveButtonTarget.classList.remove(
				"bg-base-300",
				"hover:bg-base-content/20",
				"text-base-content",
				"border-base-300",
			);
			this.saveButtonTarget.classList.add(
				"bg-placecal-orange",
				"hover:bg-orange-600",
				"text-white",
				"border-placecal-orange",
				"opacity-50",
			);
		} else {
			// Clean state and secondary - gray and faded
			this.saveButtonTarget.classList.remove(
				"bg-placecal-orange",
				"hover:bg-orange-600",
				"text-white",
				"border-placecal-orange",
			);
			this.saveButtonTarget.classList.add(
				"bg-base-300",
				"hover:bg-base-content/20",
				"text-base-content",
				"border-base-300",
				"opacity-50",
			);
		}
	}

	isSaveButtonMainAction() {
		const isSettings = this.isSettingsTab();
		const isPreview = this.isPreviewTab();
		const isBeforeSettings = this.isTabBeforeSettings();
		return isSettings || isPreview || isBeforeSettings;
	}

	getCurrentTabIndex() {
		const hash = window.location.hash.slice(1);
		if (hash && this.tabHashes.includes(hash)) {
			return this.tabHashes.indexOf(hash);
		}

		// Fall back to checked radio
		const checkedTab = document.querySelector(
			`input[name="${this.tabNameValue}"]:checked`,
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

	isTabBeforeSettings() {
		const currentIndex = this.getCurrentTabIndex();
		const nextHash = this.tabHashes[currentIndex + 1];
		return nextHash === this.settingsHashValue;
	}

	updateButtons() {
		const isFirst = this.isFirstTab();
		const isSettings = this.isSettingsTab();
		const isPreview = this.isPreviewTab();
		const isBeforeSettings = this.isTabBeforeSettings();

		// Previous button: hidden on first tab and settings tab
		if (this.hasPrevButtonTarget) {
			if (isFirst || isSettings) {
				this.prevButtonTarget.classList.add("hidden");
			} else {
				this.prevButtonTarget.classList.remove("hidden");
			}
		}

		// Continue button: hidden on settings tab, preview tab, or tab immediately before settings
		const continueHidden = isSettings || isPreview || isBeforeSettings;
		if (this.hasContinueButtonTarget) {
			if (continueHidden) {
				this.continueButtonTarget.classList.add("hidden");
			} else {
				this.continueButtonTarget.classList.remove("hidden");
			}
		}

		// Update save button style based on dirty state and position
		this.updateSaveButtonStyle();

		// Update texts based on dirty state
		this.updateButtonTexts();
	}

	// Actions for buttons
	savePrevious(event) {
		if (isDirty(this)) {
			// Save and go to previous tab
			this.setNextTab(this.getCurrentTabIndex() - 1);
			// Form will submit normally
		} else {
			// Just navigate, no save needed
			event.preventDefault();
			this.goToPreviousTab();
		}
	}

	saveOnly() {
		// Stay on current tab after save
		this.setNextTab(this.getCurrentTabIndex());
		// Form submits normally
	}

	saveContinue(event) {
		if (isDirty(this)) {
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
			sessionStorage.setItem(this.storageKeyValue, this.tabHashes[index]);
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
			`input[name="${this.tabNameValue}"][data-hash="${hash}"]`,
		);
		if (tab) {
			tab.checked = true;
			history.replaceState(null, null, `#${hash}`);
			this.updateButtons();
		}
	}
}
