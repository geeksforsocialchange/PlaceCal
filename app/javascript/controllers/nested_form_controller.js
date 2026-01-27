import { Controller } from "@hotwired/stimulus";

// Nested Form Controller - Stimulus replacement for Cocoon
// Handles adding and removing nested form fields dynamically
export default class extends Controller {
	static targets = ["template", "container", "item"];

	connect() {
		this.wrapExistingItems();
	}

	// Wrap existing items that don't have the item target
	wrapExistingItems() {
		const container = this.hasContainerTarget
			? this.containerTarget
			: this.element;
		const nestedFields = container.querySelectorAll(
			".nested-fields:not([data-nested-form-target])",
		);
		nestedFields.forEach((field) => {
			field.setAttribute("data-nested-form-target", "item");
		});
	}

	add(event) {
		event.preventDefault();

		const template = this.templateTarget.innerHTML;
		const uniqueId = new Date().getTime();

		// Replace NEW_RECORD placeholder with unique ID
		const content = template.replace(/NEW_RECORD/g, uniqueId);

		const container = this.hasContainerTarget
			? this.containerTarget
			: this.element;

		// Insert the new fields
		container.insertAdjacentHTML("beforeend", content);

		// Find the newly inserted element
		const insertedItem = container.lastElementChild;

		// Mark it as a target
		if (
			insertedItem.classList.contains("nested-fields") &&
			!insertedItem.hasAttribute("data-nested-form-target")
		) {
			insertedItem.setAttribute("data-nested-form-target", "item");
		}

		// Reinitialize Stimulus controllers on the new content
		this.reinitializeControllers(insertedItem);

		// Dispatch custom event for any listeners
		this.dispatch("added", { detail: { item: insertedItem } });

		// Notify form of change (for unsaved changes detection)
		this.notifyFormChange();
	}

	remove(event) {
		event.preventDefault();

		const item = event.target.closest(".nested-fields");
		if (!item) return;

		// Check for _destroy field (Rails nested attributes)
		const destroyField = item.querySelector("input[name*='_destroy']");

		if (destroyField) {
			// Mark for destruction and hide
			destroyField.value = "1";
			item.style.display = "none";
		} else {
			// Remove from DOM entirely (for new records)
			item.remove();
		}

		this.dispatch("removed", { detail: { item } });

		// Notify form of change (for unsaved changes detection)
		this.notifyFormChange();
	}

	// Reinitialize Stimulus controllers on dynamically added content
	reinitializeControllers(element) {
		const controllers = element.querySelectorAll("[data-controller]");
		controllers.forEach((el) => {
			const controllerValue = el.getAttribute("data-controller");
			el.removeAttribute("data-controller");
			// Use requestAnimationFrame to ensure DOM updates are processed
			requestAnimationFrame(() => {
				el.setAttribute("data-controller", controllerValue);
			});
		});
	}

	// Notify the form that something changed (for unsaved changes detection)
	notifyFormChange() {
		const form = this.element.closest("form");
		if (form) {
			form.dispatchEvent(new Event("change", { bubbles: true }));
		}
	}
}
