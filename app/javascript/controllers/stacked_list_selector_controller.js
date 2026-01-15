import { Controller } from "@hotwired/stimulus";

/**
 * Generic stacked list selector controller
 * Used by Admin::StackedListSelectorComponent for managing lists of items
 * (partnerships, partners, neighbourhoods, etc.)
 */
export default class extends Controller {
	static targets = ["list", "select", "template", "empty"];
	static values = {
		permitted: { type: Array, default: [] },
		fieldName: String,
		icon: { type: String, default: "partnership" },
		iconColor: {
			type: String,
			default: "bg-placecal-orange/10 text-placecal-orange",
		},
		removeLastWarning: String,
		cannotRemoveMessage: String,
	};

	connect() {
		this.updateEmptyState();
		this.updateSelectOptions();
	}

	add(event) {
		const select = event.target;
		const value = select.value;
		if (!value) return;

		const option = select.options[select.selectedIndex];
		const name = option.text.trim();

		// Check if already selected
		if (this.isSelected(value)) {
			this.resetSelect(select);
			return;
		}

		// Create the item
		this.addItem(value, name);

		// Reset the select
		this.resetSelect(select);
		this.updateSelectOptions();
		this.updateEmptyState();
	}

	resetSelect(select) {
		select.value = "";
		// If tom-select is used, reset it as well
		if (select.tomselect) {
			select.tomselect.clear();
		}
	}

	remove(event) {
		const item = event.target.closest("[data-item-id]");
		if (!item) return;

		const id = item.dataset.itemId;

		// Check if this is a permitted item (one the user manages)
		const isPermitted = this.isPermitted(id);
		const selectedPermitted = this.getSelectedPermittedCount();

		// If removing last permitted item, warn the user
		if (
			isPermitted &&
			selectedPermitted <= 1 &&
			this.permittedValue.length > 0
		) {
			const warning =
				this.removeLastWarningValue ||
				"Removing this item will remove your access. Are you sure?";
			if (!confirm(warning)) {
				return;
			}
		}

		// If not permitted and we have permission restrictions, don't allow removal
		if (!isPermitted && this.permittedValue.length > 0) {
			const message =
				this.cannotRemoveMessageValue ||
				"You can only remove items that you manage.";
			alert(message);
			return;
		}

		item.remove();
		this.updateSelectOptions();
		this.updateEmptyState();
		this.notifyFormChange();
	}

	addItem(id, name) {
		const template = this.templateTarget.innerHTML;
		const html = template.replace(/ITEM_ID/g, id).replace(/ITEM_NAME/g, name);

		this.listTarget.insertAdjacentHTML("beforeend", html);
		this.notifyFormChange();
	}

	isSelected(id) {
		return !!this.listTarget.querySelector(`[data-item-id="${id}"]`);
	}

	isPermitted(id) {
		if (this.permittedValue.length === 0) return true;
		return this.permittedValue.map(Number).includes(Number(id));
	}

	getSelectedIds() {
		return Array.from(this.listTarget.querySelectorAll("[data-item-id]")).map(
			(el) => el.dataset.itemId
		);
	}

	getSelectedPermittedCount() {
		const selectedIds = this.getSelectedIds().map(Number);
		const permittedIds = this.permittedValue.map(Number);
		return selectedIds.filter((id) => permittedIds.includes(id)).length;
	}

	updateSelectOptions() {
		const selectedIds = this.getSelectedIds();
		const options = this.selectTarget.options;

		for (let i = 0; i < options.length; i++) {
			const option = options[i];
			if (option.value) {
				option.disabled = selectedIds.includes(option.value);
			}
		}

		// Sync disabled state with tom-select if present
		if (this.selectTarget.tomselect) {
			const ts = this.selectTarget.tomselect;
			selectedIds.forEach((id) => {
				if (ts.options[id]) {
					ts.options[id].disabled = true;
				}
			});
			ts.refreshOptions(false);
		}
	}

	updateEmptyState() {
		const hasItems = this.listTarget.children.length > 0;
		if (this.hasEmptyTarget) {
			this.emptyTarget.classList.toggle("hidden", hasItems);
		}
	}

	// Notify the form that something changed (for unsaved changes detection)
	notifyFormChange() {
		const form = this.element.closest("form");
		if (form) {
			form.dispatchEvent(new Event("change", { bubbles: true }));
		}
	}
}
