// Shared form change tracking functionality
// Used by form-dirty and save-bar controllers

/**
 * Sets up form change tracking on a controller
 * @param {Controller} controller - Stimulus controller instance
 * @param {Object} options - Configuration options
 * @param {string} options.tabName - Tab radio name to exclude from tracking
 * @param {HTMLElement} options.form - Form element to track (defaults to controller.element or closest form)
 * @param {boolean} options.trackInitialValues - Whether to track initial values for revert detection
 * @param {Function} options.onDirtyChange - Callback when dirty state changes
 */
export function setupFormTracking(controller, options = {}) {
	const {
		tabName = "",
		form = controller.element.closest("form") || controller.element,
		trackInitialValues = false,
		onDirtyChange = () => {},
	} = options;

	controller._formTracking = {
		dirty: false,
		initialValues: new Map(),
		tabName,
		form,
		trackInitialValues,
		onDirtyChange,
	};

	// Store initial values if needed
	if (trackInitialValues) {
		getTrackableInputs(form, tabName).forEach((input) => {
			controller._formTracking.initialValues.set(input, getInputValue(input));
		});
	}

	// Bind change listeners
	bindFormChangeListeners(controller);

	// Setup beforeunload warning
	controller._boundBeforeUnload = handleBeforeUnload.bind(controller);
	window.addEventListener("beforeunload", controller._boundBeforeUnload);
}

/**
 * Cleans up form tracking listeners
 * @param {Controller} controller - Stimulus controller instance
 */
export function teardownFormTracking(controller) {
	if (controller._boundBeforeUnload) {
		window.removeEventListener("beforeunload", controller._boundBeforeUnload);
	}
}

/**
 * Marks the form as dirty
 * @param {Controller} controller - Stimulus controller instance
 */
export function markDirty(controller) {
	if (controller._formTracking.dirty) return;
	controller._formTracking.dirty = true;
	controller._formTracking.onDirtyChange(true);
}

/**
 * Marks the form as clean
 * @param {Controller} controller - Stimulus controller instance
 */
export function markClean(controller) {
	controller._formTracking.dirty = false;
	controller._formTracking.onDirtyChange(false);
}

/**
 * Checks if form has changes (when tracking initial values)
 * @param {Controller} controller - Stimulus controller instance
 * @returns {boolean} Whether form has changes from initial values
 */
export function checkDirty(controller) {
	const { initialValues, tabName, form } = controller._formTracking;
	let hasChanges = false;

	getTrackableInputs(form, tabName).forEach((input) => {
		const initial = initialValues.get(input);
		const current = getInputValue(input);
		if (initial !== current) {
			hasChanges = true;
		}
	});

	if (hasChanges !== controller._formTracking.dirty) {
		controller._formTracking.dirty = hasChanges;
		controller._formTracking.onDirtyChange(hasChanges);
	}

	return hasChanges;
}

/**
 * Returns whether the form is currently dirty
 * @param {Controller} controller - Stimulus controller instance
 * @returns {boolean} Current dirty state
 */
export function isDirty(controller) {
	return controller._formTracking?.dirty ?? false;
}

/**
 * Updates indicator visibility based on dirty state
 * @param {HTMLElement} indicator - Indicator element
 * @param {boolean} dirty - Whether form is dirty
 */
export function updateIndicator(indicator, dirty) {
	if (!indicator) return;

	if (dirty) {
		indicator.classList.remove("hidden");
		indicator.classList.add("flex");
	} else {
		indicator.classList.add("hidden");
		indicator.classList.remove("flex");
	}
}

// Private helpers

function getTrackableInputs(form, tabName) {
	return Array.from(
		form.querySelectorAll(
			"input:not([type=hidden]):not([type=file]), textarea, select",
		),
	).filter((input) => {
		if (tabName && input.name === tabName) return false;
		if (input.type === "hidden") return false;
		return true;
	});
}

function getInputValue(input) {
	if (input.type === "checkbox" || input.type === "radio") {
		return input.checked;
	}
	return input.value;
}

function bindFormChangeListeners(controller) {
	const { form, tabName, trackInitialValues } = controller._formTracking;

	const inputs = form.querySelectorAll(
		"input, textarea, select, [contenteditable]",
	);

	inputs.forEach((input) => {
		// Skip tab radio buttons and hidden system fields
		if (tabName && input.name === tabName) return;
		if (input.type === "hidden" && input.name === "_method") return;
		if (input.type === "hidden" && input.name === "authenticity_token") return;

		const handler = trackInitialValues
			? () => checkDirty(controller)
			: () => markDirty(controller);

		input.addEventListener("input", handler);
		input.addEventListener("change", handler);
	});

	// Track file inputs (can only be "changed", not reverted)
	form.querySelectorAll('input[type="file"]').forEach((input) => {
		input.addEventListener("change", () => markDirty(controller));
	});

	// Track checkboxes specifically
	form.querySelectorAll('input[type="checkbox"]').forEach((input) => {
		if (tabName && input.name === tabName) return;
		const handler = trackInitialValues
			? () => checkDirty(controller)
			: () => markDirty(controller);
		input.addEventListener("click", handler);
	});

	// Listen for form-level change events (dispatched by nested-form and stacked-list-selector controllers)
	form.addEventListener("change", (event) => {
		// Only handle if event target is the form itself (not bubbled from inputs)
		if (event.target === form) {
			markDirty(controller);
		}
	});
}

function handleBeforeUnload(event) {
	if (this._formTracking?.dirty) {
		event.preventDefault();
		event.returnValue = "You have unsaved changes.";
		return event.returnValue;
	}
}
