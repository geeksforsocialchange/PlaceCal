import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["list", "select", "template", "empty"];
	static values = {
		permitted: Array,
		fieldName: String,
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
		const name = option.text;

		// Check if already selected
		if (this.isSelected(value)) {
			select.value = "";
			return;
		}

		// Create the partnership item
		this.addPartnershipItem(value, name);

		// Reset the select
		select.value = "";
		this.updateSelectOptions();
		this.updateEmptyState();
	}

	remove(event) {
		const item = event.target.closest("[data-partnership-id]");
		if (!item) return;

		const id = item.dataset.partnershipId;
		const name = item.dataset.partnershipName;

		// Check if this is a permitted partnership (one the user manages)
		const isPermitted = this.permittedValue.map(Number).includes(Number(id));
		const selectedPermitted = this.getSelectedPermittedCount();

		// If removing last permitted partnership, warn the user
		if (isPermitted && selectedPermitted <= 1) {
			if (
				!confirm(
					"Removing this partnership will remove this partner from your partnership and you will no longer be able to access them.\n\nAre you sure you want to remove it?",
				)
			) {
				return;
			}
		}

		// If not permitted, don't allow removal
		if (!isPermitted) {
			alert("You can only remove partnerships that you manage.");
			return;
		}

		item.remove();
		this.updateSelectOptions();
		this.updateEmptyState();
	}

	addPartnershipItem(id, name) {
		const template = this.templateTarget.innerHTML;
		const html = template
			.replace(/PARTNERSHIP_ID/g, id)
			.replace(/PARTNERSHIP_NAME/g, name);

		this.listTarget.insertAdjacentHTML("beforeend", html);
	}

	isSelected(id) {
		return !!this.listTarget.querySelector(`[data-partnership-id="${id}"]`);
	}

	getSelectedIds() {
		return Array.from(
			this.listTarget.querySelectorAll("[data-partnership-id]"),
		).map((el) => el.dataset.partnershipId);
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
	}

	updateEmptyState() {
		const hasItems = this.listTarget.children.length > 0;
		if (this.hasEmptyTarget) {
			this.emptyTarget.classList.toggle("hidden", hasItems);
		}
	}
}
