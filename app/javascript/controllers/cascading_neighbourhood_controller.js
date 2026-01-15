import { Controller } from "@hotwired/stimulus";

// 5-level cascading neighbourhood selector with smart-skip
// Supports: Country (5) > Region (4) > County (3) > District (2) > Ward (1)
// Smart-skip: automatically skips levels with no options
// Smart-select: auto-selects when only one option at a level
export default class extends Controller {
	static targets = [
		"country",
		"region",
		"county",
		"district",
		"ward",
		"output",
		"loading",
	];

	static values = {
		selectedId: { type: Number, default: 0 },
	};

	// Map of level numbers to target names
	levelTargets = {
		5: "country",
		4: "region",
		3: "county",
		2: "district",
		1: "ward",
	};

	connect() {
		console.log("CascadingNeighbourhood: connect called", {
			selectedId: this.selectedIdValue,
			inTemplate: !!this.element.closest("template"),
		});

		// Skip if we're inside a template tag (used for nested form templates)
		if (this.element.closest("template")) {
			return;
		}

		// If there's already a neighbourhood selected, load the hierarchy
		const existingId = this.hasOutputTarget ? this.outputTarget.value : null;
		if (existingId && existingId !== "") {
			this.loadHierarchyForNeighbourhood(existingId);
		} else {
			// Start with countries (level 5)
			this.loadLevel(5, null);
		}
	}

	// Get CSRF token from meta tag
	get csrfToken() {
		const meta = document.querySelector('meta[name="csrf-token"]');
		return meta ? meta.getAttribute("content") : "";
	}

	// Fetch with credentials and CSRF token
	async fetchJSON(url) {
		const response = await fetch(url, {
			method: "GET",
			credentials: "same-origin",
			headers: {
				Accept: "application/json",
				"X-CSRF-Token": this.csrfToken,
				"X-Requested-With": "XMLHttpRequest",
			},
		});
		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}
		return response.json();
	}

	// Get the Stimulus target for a given level
	getTargetForLevel(level) {
		const targetName = this.levelTargets[level];
		if (!targetName) return null;

		const hasTargetMethod = `has${this.capitalize(targetName)}Target`;
		const targetProperty = `${targetName}Target`;

		return this[hasTargetMethod] ? this[targetProperty] : null;
	}

	capitalize(str) {
		return str.charAt(0).toUpperCase() + str.slice(1);
	}

	// Get placeholder text for a level
	getPlaceholder(level, optional = false) {
		const placeholders = {
			5: "Select country...",
			4: "Select region...",
			3: "Select county...",
			2: "Select district...",
			1: "Select ward...",
		};
		const base = placeholders[level] || "Select...";
		return optional ? base.replace("...", " (optional)...") : base;
	}

	// Generic level loader with smart-skip
	async loadLevel(level, parentId) {
		if (level < 1) return; // No more levels to load

		const target = this.getTargetForLevel(level);
		if (!target) {
			// No target for this level, try next level down
			await this.loadLevel(level - 1, parentId);
			return;
		}

		this.showLoading();
		try {
			const url = parentId
				? `/neighbourhoods/children?parent_id=${parentId}&level=${level}`
				: `/neighbourhoods/children?level=${level}`;

			const data = await this.fetchJSON(url);

			if (data.length === 0 && level > 1) {
				// Smart-skip: no items at this level, hide it and try next level down
				console.log(
					`CascadingNeighbourhood: Skipping level ${level} (no data)`
				);
				this.hideSelect(target);
				await this.loadLevel(level - 1, parentId);
			} else if (data.length === 1 && level > 1) {
				// Single option: auto-select and move to next level
				console.log(
					`CascadingNeighbourhood: Auto-selecting single option at level ${level}`
				);
				this.showSelect(target);
				this.populateSelect(target, data, this.getPlaceholder(level));
				target.value = data[0].id;
				// Visual hint that it was auto-selected
				target.parentElement.classList.add("opacity-60");
				this.updateOutput(data[0].id);

				// Check if this single item has children before loading next level
				if (data[0].has_children) {
					await this.loadLevel(level - 1, data[0].id);
				} else {
					this.clearLevelsBelow(level);
				}
			} else {
				// Multiple options: show the dropdown
				this.showSelect(target);
				target.parentElement.classList.remove("opacity-60");
				// Make ward optional since it's the final level
				const isOptional = level === 1;
				this.populateSelect(
					target,
					data,
					this.getPlaceholder(level, isOptional)
				);
				this.clearLevelsBelow(level);
			}
		} catch (error) {
			console.error(
				`CascadingNeighbourhood: Error loading level ${level}:`,
				error
			);
		} finally {
			this.hideLoading();
		}
	}

	// Event handlers for each level
	async countryChanged(event) {
		await this.levelChanged(5, event.target.value);
	}

	async regionChanged(event) {
		await this.levelChanged(4, event.target.value);
	}

	async countyChanged(event) {
		await this.levelChanged(3, event.target.value);
	}

	async districtChanged(event) {
		await this.levelChanged(2, event.target.value);
	}

	wardChanged(event) {
		const wardId = event.target.value;
		if (wardId) {
			this.updateOutput(wardId);
		} else {
			// Revert to parent selection
			this.revertToHighestSelected();
		}
	}

	// Generic level change handler
	async levelChanged(level, selectedId) {
		if (!selectedId) {
			this.clearLevelsBelow(level);
			this.revertToHighestSelected();
			return;
		}

		// Update output to the selected value
		this.updateOutput(selectedId);

		// Remove auto-select styling if user manually selected
		const target = this.getTargetForLevel(level);
		if (target) {
			target.parentElement.classList.remove("opacity-60");
		}

		// Load children for the next level down
		await this.loadLevel(level - 1, selectedId);
	}

	// Find the highest level with a selection and update output
	revertToHighestSelected() {
		const levels = [5, 4, 3, 2, 1];
		for (const level of levels) {
			const target = this.getTargetForLevel(level);
			if (target && target.value && !target.disabled) {
				this.updateOutput(target.value);
				return;
			}
		}
		this.updateOutput(null);
	}

	// Populate a select element with options
	populateSelect(select, items, placeholder) {
		select.innerHTML = `<option value="">${placeholder}</option>`;
		items.forEach((item) => {
			const option = document.createElement("option");
			option.value = item.id;
			option.textContent = item.name;
			select.appendChild(option);
		});
		select.disabled = items.length === 0;
	}

	// Clear a select and disable it
	clearSelect(select, placeholder = "Select...") {
		select.innerHTML = `<option value="">${placeholder}</option>`;
		select.disabled = true;
		select.parentElement.classList.remove("opacity-60");
	}

	// Clear all levels below the given level
	clearLevelsBelow(level) {
		for (let l = level - 1; l >= 1; l--) {
			const target = this.getTargetForLevel(l);
			if (target) {
				this.clearSelect(target, this.getPlaceholder(l, l === 1));
			}
		}
	}

	// Show a select's fieldset
	showSelect(select) {
		const fieldset = select.closest("fieldset");
		if (fieldset) {
			fieldset.classList.remove("hidden");
		}
	}

	// Hide a select's fieldset
	hideSelect(select) {
		const fieldset = select.closest("fieldset");
		if (fieldset) {
			fieldset.classList.add("hidden");
		}
		select.value = "";
		select.disabled = true;
	}

	// Update the hidden output field
	updateOutput(neighbourhoodId) {
		if (this.hasOutputTarget) {
			this.outputTarget.value = neighbourhoodId || "";
			console.log(
				`CascadingNeighbourhood: Output updated to ${neighbourhoodId}`
			);
		}
	}

	// Show loading spinner
	showLoading() {
		if (this.hasLoadingTarget) {
			this.loadingTarget.classList.remove("hidden");
		}
	}

	// Hide loading spinner
	hideLoading() {
		if (this.hasLoadingTarget) {
			this.loadingTarget.classList.add("hidden");
		}
	}

	// Load the full hierarchy when editing an existing service area
	async loadHierarchyForNeighbourhood(neighbourhoodId) {
		if (!neighbourhoodId) return;

		console.log(
			`CascadingNeighbourhood: Loading hierarchy for neighbourhood ${neighbourhoodId}`
		);
		this.showLoading();

		try {
			// Get the hierarchy data for this neighbourhood
			const data = await this.fetchJSON(
				`/neighbourhoods/hierarchy?neighbourhood_id=${neighbourhoodId}`
			);
			console.log("CascadingNeighbourhood: hierarchy data", data);

			// Load countries first (level 5)
			const countriesData = await this.fetchJSON(
				`/neighbourhoods/children?level=5`
			);
			const countryTarget = this.getTargetForLevel(5);
			if (countryTarget) {
				this.showSelect(countryTarget);
				this.populateSelect(
					countryTarget,
					countriesData,
					this.getPlaceholder(5)
				);

				if (data.country_id) {
					countryTarget.value = data.country_id;

					// Load regions (level 4)
					await this.loadAndSelectLevel(4, data.country_id, data.region_id);

					if (data.region_id) {
						// Load counties (level 3)
						await this.loadAndSelectLevel(3, data.region_id, data.county_id);

						const countyOrRegionId = data.county_id || data.region_id;
						if (countyOrRegionId) {
							// Load districts (level 2)
							await this.loadAndSelectLevel(
								2,
								countyOrRegionId,
								data.district_id
							);

							const districtId = data.district_id || countyOrRegionId;
							if (districtId && data.neighbourhood_level === 1) {
								// Load wards (level 1)
								await this.loadAndSelectLevel(1, districtId, neighbourhoodId);
							}
						}
					}
				}
			}
		} catch (error) {
			console.error("CascadingNeighbourhood: Error loading hierarchy:", error);
			// Fall back to loading empty countries
			this.loadLevel(5, null);
		} finally {
			this.hideLoading();
		}
	}

	// Helper to load and optionally select a value at a level
	async loadAndSelectLevel(level, parentId, valueToSelect) {
		const target = this.getTargetForLevel(level);
		if (!target) return;

		try {
			const data = await this.fetchJSON(
				`/neighbourhoods/children?parent_id=${parentId}&level=${level}`
			);

			if (data.length === 0) {
				// No data at this level, hide it
				this.hideSelect(target);
			} else {
				this.showSelect(target);
				const isOptional = level === 1;
				this.populateSelect(
					target,
					data,
					this.getPlaceholder(level, isOptional)
				);

				if (valueToSelect) {
					target.value = valueToSelect;
				}
			}
		} catch (error) {
			console.error(
				`CascadingNeighbourhood: Error loading level ${level}:`,
				error
			);
			this.hideSelect(target);
		}
	}
}
