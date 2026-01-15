import { Controller } from "@hotwired/stimulus";

// Admin Table Controller - Modern admin table with server-side features
// Provides pagination, search, sorting, and filtering
export default class extends Controller {
	static targets = [
		"table",
		"tbody",
		"search",
		"info",
		"pagination",
		"summary",
		"filter",
		"radioFilter",
		"clearFilters",
		"clearSort",
		"sortIcon",
		"dependentFilter",
	];
	static values = {
		source: String,
		columns: Array,
		pageLength: { type: Number, default: 25 },
		defaultSortColumn: { type: String, default: "" },
		defaultSortDirection: { type: String, default: "desc" },
	};

	connect() {
		this.currentPage = 0;
		this.searchTerm = "";
		this.sortColumn = this.defaultSortColumnValue || null;
		this.sortDirection = this.defaultSortDirectionValue || "desc";
		this.totalRecords = 0;
		this.filteredRecords = 0;
		this.filters = {};
		this.searchDebounceTimer = null;

		// Apply default filter values
		this.applyDefaultFilters();

		this.loadData();
	}

	applyDefaultFilters() {
		// Apply defaults from dropdown filters
		this.filterTargets.forEach((select) => {
			const defaultValue = select.dataset.filterDefault;
			if (defaultValue) {
				const column = select.dataset.filterColumn;
				this.filters[column] = defaultValue;
				// The selected attribute is already set in the template
			}
		});
	}

	search(event) {
		// Debounce search for better UX
		clearTimeout(this.searchDebounceTimer);
		this.searchDebounceTimer = setTimeout(() => {
			this.searchTerm = event.target.value;
			this.currentPage = 0;
			this.loadData();
		}, 300);
	}

	sort(event) {
		const column = event.currentTarget.dataset.column;
		if (this.sortColumn === column) {
			this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc";
		} else {
			this.sortColumn = column;
			this.sortDirection = "asc";
		}
		this.currentPage = 0;
		this.loadData();
		this.updateSortIndicators();
		this.updateClearSortButton();
	}

	resetSort() {
		this.sortColumn = this.defaultSortColumnValue || null;
		this.sortDirection = this.defaultSortDirectionValue || "desc";
		this.currentPage = 0;
		this.loadData();
		this.updateSortIndicators();
		this.updateClearSortButton();
	}

	updateClearSortButton() {
		if (this.hasClearSortTarget) {
			const isDefaultSort =
				this.sortColumn === (this.defaultSortColumnValue || null) &&
				this.sortDirection === (this.defaultSortDirectionValue || "desc");

			this.clearSortTarget.style.display = isDefaultSort
				? "none"
				: "inline-flex";
		}
	}

	get visibleColumnsCount() {
		return this.columnsValue.filter((col) => !col.hidden).length;
	}

	applyFilter(event) {
		const column = event.target.dataset.filterColumn;
		const value = event.target.value;

		if (value) {
			this.filters[column] = value;
		} else {
			delete this.filters[column];
		}

		// Check if this filter has dependent filters that need updating
		const dependsOn = event.target.dataset.filterDependsOn;
		if (!dependsOn) {
			// This might be a parent filter - update any dependent filters
			this.updateDependentFilters(column, value);
		}

		this.currentPage = 0;
		this.loadData();
		this.updateClearFiltersButton();
	}

	applyRadioFilter(event) {
		const button = event.currentTarget;
		const container = button.closest("[data-admin-table-target='radioFilter']");
		const column = container.dataset.filterColumn;
		const value = button.dataset.filterValue;
		const isAllButton = button.dataset.isAll === "true";

		// Reset all buttons to unselected state
		container.querySelectorAll("button").forEach((btn) => {
			btn.classList.remove(
				"bg-white",
				"bg-orange-500",
				"text-gray-900",
				"text-white",
				"shadow-sm"
			);
			btn.classList.add("text-gray-500", "hover:text-gray-700");
		});

		// Apply selected state to clicked button
		button.classList.remove("text-gray-500", "hover:text-gray-700");
		if (isAllButton) {
			button.classList.add("bg-white", "text-gray-900", "shadow-sm");
		} else {
			button.classList.add("bg-orange-500", "text-white", "shadow-sm");
		}

		if (value) {
			this.filters[column] = value;
		} else {
			delete this.filters[column];
		}

		this.currentPage = 0;
		this.loadData();
		this.updateClearFiltersButton();
	}

	// Update dependent filter dropdowns when parent filter changes
	updateDependentFilters(parentColumn, parentValue) {
		this.dependentFilterTargets.forEach((select) => {
			if (select.dataset.filterDependsOn === parentColumn) {
				const childColumn = select.dataset.filterColumn;

				// Clear the dependent filter value
				select.value = "";
				delete this.filters[childColumn];

				// Show/hide the select based on whether parent has a value
				if (parentValue) {
					select.classList.remove("hidden");

					// Show only options matching the parent value
					const options = select.querySelectorAll("option[data-parent]");
					options.forEach((option) => {
						option.hidden = option.dataset.parent !== parentValue;
					});
				} else {
					select.classList.add("hidden");
				}
			}
		});
	}

	clearFilters() {
		this.filters = {};
		// Reset dropdown filters to default or empty
		this.filterTargets.forEach((select) => {
			const defaultValue = select.dataset.filterDefault;
			if (defaultValue) {
				select.value = defaultValue;
				this.filters[select.dataset.filterColumn] = defaultValue;
			} else {
				select.value = "";
			}
		});
		// Also reset and hide dependent filters
		this.dependentFilterTargets.forEach((select) => {
			select.value = "";
			select.classList.add("hidden");
		});
		// Reset radio button filters to "All"
		this.radioFilterTargets.forEach((container) => {
			container.querySelectorAll("button").forEach((btn) => {
				btn.classList.remove(
					"bg-white",
					"bg-orange-500",
					"text-gray-900",
					"text-white",
					"shadow-sm"
				);
				btn.classList.add("text-gray-500", "hover:text-gray-700");
			});
			const allBtn = container.querySelector('button[data-filter-value=""]');
			if (allBtn) {
				allBtn.classList.remove("text-gray-500", "hover:text-gray-700");
				allBtn.classList.add("bg-white", "text-gray-900", "shadow-sm");
			}
		});
		this.currentPage = 0;
		this.loadData();
		this.updateClearFiltersButton();
	}

	filterByValue(event) {
		const column = event.currentTarget.dataset.filterColumn;
		const value = event.currentTarget.dataset.filterValue;

		if (column && value) {
			this.filters[column] = value;

			// Update the corresponding dropdown to match
			this.filterTargets.forEach((select) => {
				if (select.dataset.filterColumn === column) {
					select.value = value;
				}
			});

			// Update the corresponding radio button filter to match
			this.radioFilterTargets.forEach((container) => {
				if (container.dataset.filterColumn === column) {
					container.querySelectorAll("button").forEach((btn) => {
						btn.classList.remove(
							"bg-white",
							"bg-orange-500",
							"text-gray-900",
							"text-white",
							"shadow-sm"
						);
						btn.classList.add("text-gray-500", "hover:text-gray-700");
					});
					const btn = container.querySelector(
						`button[data-filter-value="${value}"]`
					);
					if (btn) {
						btn.classList.remove("text-gray-500", "hover:text-gray-700");
						btn.classList.add("bg-orange-500", "text-white", "shadow-sm");
					}
				}
			});

			this.currentPage = 0;
			this.loadData();
			this.updateClearFiltersButton();
		}
	}

	updateClearFiltersButton() {
		if (this.hasClearFiltersTarget) {
			// Check if current filters differ from defaults
			const hasNonDefaultFilters = this.hasNonDefaultFilters();
			this.clearFiltersTarget.style.display = hasNonDefaultFilters
				? "inline-flex"
				: "none";
		}
	}

	hasNonDefaultFilters() {
		// Build object of default filter values
		const defaults = {};
		this.filterTargets.forEach((select) => {
			const defaultValue = select.dataset.filterDefault;
			if (defaultValue) {
				defaults[select.dataset.filterColumn] = defaultValue;
			}
		});

		// Check if current filters differ from defaults
		const currentKeys = Object.keys(this.filters);
		const defaultKeys = Object.keys(defaults);

		// If we have filters that aren't defaults, show button
		for (const key of currentKeys) {
			if (!(key in defaults) || this.filters[key] !== defaults[key]) {
				return true;
			}
		}

		// If we're missing a default filter, show button
		for (const key of defaultKeys) {
			if (!(key in this.filters) || this.filters[key] !== defaults[key]) {
				return true;
			}
		}

		return false;
	}

	goToPage(event) {
		event.preventDefault();
		const page = parseInt(event.currentTarget.dataset.page, 10);
		if (page >= 0 && page < this.totalPages) {
			this.currentPage = page;
			this.loadData();
		}
	}

	previousPage(event) {
		event.preventDefault();
		if (this.currentPage > 0) {
			this.currentPage--;
			this.loadData();
		}
	}

	nextPage(event) {
		event.preventDefault();
		if (this.currentPage < this.totalPages - 1) {
			this.currentPage++;
			this.loadData();
		}
	}

	firstPage(event) {
		event.preventDefault();
		this.currentPage = 0;
		this.loadData();
	}

	lastPage(event) {
		event.preventDefault();
		this.currentPage = this.totalPages - 1;
		this.loadData();
	}

	async loadData() {
		const params = new URLSearchParams({
			draw: Date.now(),
			start: this.currentPage * this.pageLengthValue,
			length: this.pageLengthValue,
			"search[value]": this.searchTerm,
			"search[regex]": "false",
		});

		// Add column data for DataTables compatibility
		this.columnsValue.forEach((col, i) => {
			params.append(`columns[${i}][data]`, col.data);
			params.append(`columns[${i}][name]`, col.data);
			params.append(
				`columns[${i}][searchable]`,
				col.searchable !== false ? "true" : "false"
			);
			params.append(
				`columns[${i}][orderable]`,
				col.orderable !== false ? "true" : "false"
			);
			params.append(`columns[${i}][search][value]`, "");
			params.append(`columns[${i}][search][regex]`, "false");
		});

		// Add sorting
		const sortColIndex = this.sortColumn
			? this.columnsValue.findIndex((c) => c.data === this.sortColumn)
			: -1;
		params.append("order[0][column]", sortColIndex >= 0 ? sortColIndex : 0);
		params.append("order[0][dir]", this.sortDirection);
		// Also send column name for non-visible columns like updated_at
		if (this.sortColumn) {
			params.append("sort_column", this.sortColumn);
		}

		// Add custom filters
		Object.entries(this.filters).forEach(([key, value]) => {
			params.append(`filter[${key}]`, value);
		});

		try {
			this.showLoading();
			const response = await fetch(`${this.sourceValue}?${params}`);
			const data = await response.json();

			this.totalRecords = data.recordsTotal;
			this.filteredRecords = data.recordsFiltered;
			this.totalPages = Math.ceil(this.filteredRecords / this.pageLengthValue);

			this.renderTable(data.data);
			this.renderPagination();
			this.renderInfo();
			this.renderSummary();
		} catch (error) {
			console.error("Error loading table data:", error);
			this.showError();
		}
	}

	showLoading() {
		this.tbodyTarget.innerHTML = `
      <tr>
        <td colspan="${this.visibleColumnsCount}" class="px-6 py-12 text-center">
          <div class="flex flex-col items-center justify-center text-gray-500">
            <svg style="width: 2rem; height: 2rem; animation: spin 1s linear infinite; color: #e87d1e;" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle style="opacity: 0.25;" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path style="opacity: 0.75;" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span class="mt-2 text-sm">Loading data...</span>
          </div>
        </td>
      </tr>
    `;
	}

	showError() {
		this.tbodyTarget.innerHTML = `
      <tr>
        <td colspan="${this.visibleColumnsCount}" class="px-6 py-12 text-center">
          <div class="flex flex-col items-center justify-center text-red-500">
            <svg class="w-8 h-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
            </svg>
            <span class="text-sm font-medium">Error loading data</span>
            <button class="mt-2 text-sm text-orange-600 hover:text-orange-700 underline" data-action="click->admin-table#loadData">
              Try again
            </button>
          </div>
        </td>
      </tr>
    `;
	}

	renderTable(data) {
		if (data.length === 0) {
			this.tbodyTarget.innerHTML = `
        <tr>
          <td colspan="${this.visibleColumnsCount}" class="px-6 py-12 text-center">
            <div class="flex flex-col items-center justify-center text-gray-400">
              <svg class="w-12 h-12 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
              </svg>
              <span class="text-sm font-medium">No records found</span>
              <span class="text-xs mt-1">Try adjusting your search or filters</span>
            </div>
          </td>
        </tr>
      `;
			return;
		}

		this.tbodyTarget.innerHTML = data
			.map((row) => {
				// Build row attributes from DT_RowAttr (e.g., inline styles)
				let rowAttrs = "";
				if (row.DT_RowAttr) {
					Object.entries(row.DT_RowAttr).forEach(([key, value]) => {
						rowAttrs += ` ${key}="${value}"`;
					});
				}
				// Build row classes
				const rowClass = row.DT_RowClass
					? `${row.DT_RowClass} hover:bg-orange-50/30 transition-colors`
					: "hover:bg-orange-50/30 transition-colors";

				return `
        <tr class="${rowClass}"${rowAttrs}>
          ${this.columnsValue
						.filter((col) => !col.hidden)
						.map(
							(col) =>
								`<td class="px-4 py-4 text-sm">${row[col.data] ?? ""}</td>`
						)
						.join("")}
        </tr>
      `;
			})
			.join("");
	}

	renderPagination() {
		if (!this.hasPaginationTarget) return;

		if (this.totalPages <= 1) {
			this.paginationTarget.innerHTML = "";
			return;
		}

		const pages = [];
		const maxVisiblePages = 5;
		let startPage = Math.max(
			0,
			this.currentPage - Math.floor(maxVisiblePages / 2)
		);
		let endPage = Math.min(this.totalPages, startPage + maxVisiblePages);

		if (endPage - startPage < maxVisiblePages) {
			startPage = Math.max(0, endPage - maxVisiblePages);
		}

		const btnBase =
			"inline-flex items-center justify-center w-9 h-9 text-sm font-medium rounded-lg transition-colors";
		const btnEnabled = "text-gray-700 hover:bg-gray-100";
		const btnDisabled = "text-gray-300 cursor-not-allowed";
		const btnActive = "bg-orange-500 text-white shadow-sm";

		// Previous button
		pages.push(`
      <li>
        <a class="${btnBase} ${
			this.currentPage === 0 ? btnDisabled : btnEnabled
		}" href="#" data-action="admin-table#previousPage" ${
			this.currentPage === 0 ? 'tabindex="-1"' : ""
		}>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
          </svg>
        </a>
      </li>
    `);

		// Page numbers
		for (let i = startPage; i < endPage; i++) {
			pages.push(`
        <li>
          <a class="${btnBase} ${
				i === this.currentPage ? btnActive : btnEnabled
			}" href="#" data-action="admin-table#goToPage" data-page="${i}">${
				i + 1
			}</a>
        </li>
      `);
		}

		// Next button
		pages.push(`
      <li>
        <a class="${btnBase} ${
			this.currentPage >= this.totalPages - 1 ? btnDisabled : btnEnabled
		}" href="#" data-action="admin-table#nextPage" ${
			this.currentPage >= this.totalPages - 1 ? 'tabindex="-1"' : ""
		}>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
          </svg>
        </a>
      </li>
    `);

		this.paginationTarget.innerHTML = pages.join("");
	}

	renderInfo() {
		if (!this.hasInfoTarget) return;

		const start =
			this.filteredRecords > 0
				? this.currentPage * this.pageLengthValue + 1
				: 0;
		const end = Math.min(
			(this.currentPage + 1) * this.pageLengthValue,
			this.filteredRecords
		);

		if (this.filteredRecords === 0) {
			this.infoTarget.textContent = "No entries";
		} else if (this.filteredRecords === this.totalRecords) {
			this.infoTarget.textContent = `${start}–${end} of ${this.totalRecords}`;
		} else {
			this.infoTarget.textContent = `${start}–${end} of ${this.filteredRecords} (filtered)`;
		}
	}

	renderSummary() {
		if (!this.hasSummaryTarget) return;

		if (this.filteredRecords === this.totalRecords) {
			this.summaryTarget.textContent = `${this.totalRecords} total records`;
		} else {
			this.summaryTarget.textContent = `Showing ${this.filteredRecords} of ${this.totalRecords} records`;
		}
	}

	updateSortIndicators() {
		// Only update SVGs with sortIcon target, not header icons
		this.sortIconTargets.forEach((icon) => {
			const column = icon.dataset.column;
			if (column === this.sortColumn) {
				icon.style.opacity = "1";
				icon.innerHTML =
					this.sortDirection === "asc"
						? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path>'
						: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>';
			} else {
				icon.style.opacity = "0.3";
				icon.innerHTML =
					'<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"></path>';
			}
		});
	}
}
