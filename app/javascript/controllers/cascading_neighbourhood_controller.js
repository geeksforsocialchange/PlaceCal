import { Controller } from "@hotwired/stimulus";

// Cascading neighbourhood selector
// Allows hierarchical selection: Country > Region > District/County > Ward
// Supports selecting at any level (region, district, or ward)
export default class extends Controller {
	static targets = ["region", "district", "ward", "output", "loading"];
	static values = {
		country: { type: Number, default: 0 },
	};

	connect() {
		console.log("CascadingNeighbourhood: connect called", {
			countryValue: this.countryValue,
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
			this.loadRegions();
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

	async loadRegions() {
		if (!this.countryValue) return;

		this.showLoading();
		try {
			const url = `/neighbourhoods/children?parent_id=${this.countryValue}&unit=region`;
			const data = await this.fetchJSON(url);
			this.populateSelect(this.regionTarget, data, "Select region...");
			this.clearSelect(this.districtTarget, "Select area...");
			this.clearSelect(this.wardTarget, "Select ward (optional)...");
		} catch (error) {
			console.error("CascadingNeighbourhood: Error loading regions:", error);
		} finally {
			this.hideLoading();
		}
	}

	async regionChanged(event) {
		const regionId = event.target.value;
		if (!regionId) {
			this.clearSelect(this.districtTarget, "Select area...");
			this.clearSelect(this.wardTarget, "Select ward (optional)...");
			this.updateOutput(null);
			return;
		}

		// When region is selected, that becomes the output (can be refined further)
		this.updateOutput(regionId);

		this.showLoading();
		try {
			const data = await this.fetchJSON(
				`/neighbourhoods/children?parent_id=${regionId}&unit=district`
			);
			this.populateSelect(
				this.districtTarget,
				data,
				"Select area (optional)..."
			);
			this.clearSelect(this.wardTarget, "Select ward (optional)...");
		} catch (error) {
			console.error("CascadingNeighbourhood: Error loading districts:", error);
		} finally {
			this.hideLoading();
		}
	}

	async districtChanged(event) {
		const districtId = event.target.value;
		if (!districtId) {
			// Revert to region selection
			const regionId = this.regionTarget.value;
			this.updateOutput(regionId || null);
			this.clearSelect(this.wardTarget, "Select ward (optional)...");
			return;
		}

		// District/county selected - update output
		this.updateOutput(districtId);

		this.showLoading();
		try {
			const data = await this.fetchJSON(
				`/neighbourhoods/children?parent_id=${districtId}&unit=ward`
			);
			if (data.length > 0) {
				this.populateSelect(this.wardTarget, data, "Select ward (optional)...");
			} else {
				this.clearSelect(this.wardTarget, "No wards available");
				this.wardTarget.disabled = true;
			}
		} catch (error) {
			console.error("CascadingNeighbourhood: Error loading wards:", error);
		} finally {
			this.hideLoading();
		}
	}

	wardChanged(event) {
		const wardId = event.target.value;
		if (wardId) {
			this.updateOutput(wardId);
		} else {
			// Revert to district selection
			const districtId = this.districtTarget.value;
			this.updateOutput(districtId || this.regionTarget.value || null);
		}
	}

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

	clearSelect(select, placeholder) {
		select.innerHTML = `<option value="">${placeholder}</option>`;
		select.disabled = true;
	}

	updateOutput(neighbourhoodId) {
		if (this.hasOutputTarget) {
			this.outputTarget.value = neighbourhoodId || "";
		}
	}

	showLoading() {
		if (this.hasLoadingTarget) {
			this.loadingTarget.classList.remove("hidden");
		}
	}

	hideLoading() {
		if (this.hasLoadingTarget) {
			this.loadingTarget.classList.add("hidden");
		}
	}

	// Load the full hierarchy when editing an existing service area
	async loadHierarchyForNeighbourhood(neighbourhoodId) {
		if (!neighbourhoodId) return;

		this.showLoading();
		try {
			const data = await this.fetchJSON(
				`/neighbourhoods/hierarchy?neighbourhood_id=${neighbourhoodId}`
			);
			console.log("CascadingNeighbourhood: hierarchy data", data);

			// Load regions first
			const regionsData = await this.fetchJSON(
				`/neighbourhoods/children?parent_id=${this.countryValue}&unit=region`
			);
			this.populateSelect(this.regionTarget, regionsData, "Select region...");

			if (data.region_id) {
				this.regionTarget.value = data.region_id;

				// Load districts/counties
				const districtsData = await this.fetchJSON(
					`/neighbourhoods/children?parent_id=${data.region_id}&unit=district`
				);
				this.populateSelect(
					this.districtTarget,
					districtsData,
					"Select area (optional)..."
				);

				if (data.district_id) {
					this.districtTarget.value = data.district_id;

					// If the selected neighbourhood is a ward, load wards
					if (data.neighbourhood_unit === "ward") {
						const wardsData = await this.fetchJSON(
							`/neighbourhoods/children?parent_id=${data.district_id}&unit=ward`
						);
						this.populateSelect(
							this.wardTarget,
							wardsData,
							"Select ward (optional)..."
						);
						this.wardTarget.value = neighbourhoodId;
					} else {
						// The selection IS the district, show empty ward selector
						this.clearSelect(this.wardTarget, "Select ward (optional)...");
						// Try to load wards anyway in case user wants to drill down
						try {
							const wardsData = await this.fetchJSON(
								`/neighbourhoods/children?parent_id=${data.district_id}&unit=ward`
							);
							if (wardsData.length > 0) {
								this.populateSelect(
									this.wardTarget,
									wardsData,
									"Select ward (optional)..."
								);
							}
						} catch (e) {
							// Ignore - wards not available
						}
					}
				} else if (data.neighbourhood_unit === "region") {
					// Region-level selection
					this.clearSelect(this.districtTarget, "Select area (optional)...");
					this.districtTarget.disabled = false;
					this.clearSelect(this.wardTarget, "Select ward (optional)...");
				}
			}
		} catch (error) {
			console.error("CascadingNeighbourhood: Error loading hierarchy:", error);
			// Fall back to loading empty regions
			this.loadRegions();
		} finally {
			this.hideLoading();
		}
	}
}
