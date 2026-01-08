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
		"clearFilters",
		"sortIcon",
		"dependentFilter",
	];
	static values = {
		source: String,
		columns: Array,
		pageLength: { type: Number, default: 25 },
	};

	connect() {
		this.currentPage = 0;
		this.searchTerm = "";
		this.sortColumn = null;
		this.sortDirection = "asc";
		this.totalRecords = 0;
		this.filteredRecords = 0;
		this.filters = {};
		this.searchDebounceTimer = null;

		this.loadData();
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

	// Update dependent filter dropdowns when parent filter changes
	updateDependentFilters(parentColumn, parentValue) {
		this.dependentFilterTargets.forEach((select) => {
			if (select.dataset.filterDependsOn === parentColumn) {
				const childColumn = select.dataset.filterColumn;

				// Clear the dependent filter
				select.value = "";
				delete this.filters[childColumn];

				// Show/hide options based on parent value
				const options = select.querySelectorAll("option[data-parent]");
				options.forEach((option) => {
					if (!parentValue || option.dataset.parent === parentValue) {
						option.style.display = "";
					} else {
						option.style.display = "none";
					}
				});

				// Enable/disable the select based on whether parent has a value
				select.disabled = !parentValue;
				if (!parentValue) {
					select.classList.add("opacity-50", "cursor-not-allowed");
				} else {
					select.classList.remove("opacity-50", "cursor-not-allowed");
				}
			}
		});
	}

	clearFilters() {
		this.filters = {};
		this.filterTargets.forEach((select) => {
			select.value = "";
		});
		// Also reset dependent filters
		this.dependentFilterTargets.forEach((select) => {
			select.value = "";
			select.disabled = true;
			select.classList.add("opacity-50", "cursor-not-allowed");
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

			this.currentPage = 0;
			this.loadData();
			this.updateClearFiltersButton();
		}
	}

	updateClearFiltersButton() {
		if (this.hasClearFiltersTarget) {
			const hasFilters = Object.keys(this.filters).length > 0;
			this.clearFiltersTarget.classList.toggle("hidden", !hasFilters);
		}
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

		// Add sorting (default to first column ascending if not set)
		const sortColIndex =
			this.sortColumn !== null
				? this.columnsValue.findIndex((c) => c.data === this.sortColumn)
				: 0;
		params.append("order[0][column]", sortColIndex >= 0 ? sortColIndex : 0);
		params.append("order[0][dir]", this.sortDirection);

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
        <td colspan="${this.columnsValue.length}" class="px-6 py-12 text-center">
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
        <td colspan="${this.columnsValue.length}" class="px-6 py-12 text-center">
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
          <td colspan="${this.columnsValue.length}" class="px-6 py-12 text-center">
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
			.map(
				(row) => `
        <tr class="hover:bg-orange-50/30 transition-colors">
          ${this.columnsValue
						.map(
							(col) =>
								`<td class="px-6 py-4 text-sm">${row[col.data] ?? ""}</td>`
						)
						.join("")}
        </tr>
      `
			)
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
		this.tableTarget.querySelectorAll("th[data-column]").forEach((th) => {
			const icon = th.querySelector("svg");
			if (icon) {
				if (th.dataset.column === this.sortColumn) {
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
			}
		});
	}
}
