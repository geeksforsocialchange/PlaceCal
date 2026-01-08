import { Controller } from "@hotwired/stimulus";

// Admin Table Controller - Vanilla JS replacement for jQuery DataTables
// Provides server-side pagination, search, and sorting without jQuery
export default class extends Controller {
	static targets = ["table", "tbody", "search", "info", "pagination"];
	static values = {
		source: String,
		columns: Array,
		pageLength: { type: Number, default: 15 },
	};

	connect() {
		this.currentPage = 0;
		this.searchTerm = "";
		this.sortColumn = null;
		this.sortDirection = "asc";
		this.totalRecords = 0;
		this.filteredRecords = 0;

		this.loadData();
	}

	search(event) {
		this.searchTerm = event.target.value;
		this.currentPage = 0;
		this.loadData();
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

		// Add column data for DataTables compatibility (all required fields)
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
		} catch (error) {
			console.error("Error loading table data:", error);
			this.showError();
		}
	}

	showLoading() {
		this.tbodyTarget.innerHTML = `
      <tr>
        <td colspan="${this.columnsValue.length}" class="px-6 py-4 text-center text-gray-500">
          <svg class="animate-spin inline-block h-5 w-5 mr-2 text-orange-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Loading...
        </td>
      </tr>
    `;
	}

	showError() {
		this.tbodyTarget.innerHTML = `
      <tr>
        <td colspan="${this.columnsValue.length}" class="px-6 py-4 text-center text-red-600">
          Error loading data. Please try again.
        </td>
      </tr>
    `;
	}

	renderTable(data) {
		if (data.length === 0) {
			this.tbodyTarget.innerHTML = `
        <tr>
          <td colspan="${this.columnsValue.length}" class="px-6 py-4 text-center text-gray-500">
            No records found
          </td>
        </tr>
      `;
			return;
		}

		this.tbodyTarget.innerHTML = data
			.map(
				(row) => `
        <tr class="hover:bg-gray-50">
          ${this.columnsValue
						.map(
							(col) =>
								`<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${
									row[col.data] ?? ""
								}</td>`
						)
						.join("")}
        </tr>
      `
			)
			.join("");
	}

	renderPagination() {
		if (!this.hasPaginationTarget) return;

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
			"relative inline-flex items-center px-3 py-2 text-sm font-medium border";
		const btnEnabled =
			"bg-white text-gray-700 border-gray-300 hover:bg-gray-50";
		const btnDisabled =
			"bg-gray-100 text-gray-400 border-gray-300 cursor-not-allowed";
		const btnActive = "bg-orange-500 text-white border-orange-500";

		// First and Previous buttons
		pages.push(`
      <li>
        <a class="${btnBase} ${
			this.currentPage === 0 ? btnDisabled : btnEnabled
		} rounded-l-md" href="#" data-action="admin-table#firstPage">&laquo;</a>
      </li>
      <li>
        <a class="${btnBase} ${
			this.currentPage === 0 ? btnDisabled : btnEnabled
		}" href="#" data-action="admin-table#previousPage">&lsaquo;</a>
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

		// Next and Last buttons
		pages.push(`
      <li>
        <a class="${btnBase} ${
			this.currentPage >= this.totalPages - 1 ? btnDisabled : btnEnabled
		}" href="#" data-action="admin-table#nextPage">&rsaquo;</a>
      </li>
      <li>
        <a class="${btnBase} ${
			this.currentPage >= this.totalPages - 1 ? btnDisabled : btnEnabled
		} rounded-r-md" href="#" data-action="admin-table#lastPage">&raquo;</a>
      </li>
    `);

		this.paginationTarget.innerHTML = pages.join("");
	}

	renderInfo() {
		if (!this.hasInfoTarget) return;

		const start = this.currentPage * this.pageLengthValue + 1;
		const end = Math.min(
			(this.currentPage + 1) * this.pageLengthValue,
			this.filteredRecords
		);

		if (this.filteredRecords === 0) {
			this.infoTarget.textContent = "No entries to show";
		} else if (this.filteredRecords === this.totalRecords) {
			this.infoTarget.textContent = `Showing ${start} to ${end} of ${this.totalRecords} entries`;
		} else {
			this.infoTarget.textContent = `Showing ${start} to ${end} of ${this.filteredRecords} entries (filtered from ${this.totalRecords} total)`;
		}
	}

	updateSortIndicators() {
		// Remove existing sort indicators
		this.tableTarget.querySelectorAll("th[data-column]").forEach((th) => {
			th.classList.remove("sorting_asc", "sorting_desc");
			if (th.dataset.column === this.sortColumn) {
				th.classList.add(`sorting_${this.sortDirection}`);
			}
		});
	}
}
