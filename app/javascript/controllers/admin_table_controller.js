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
        <td colspan="${this.columnsValue.length}" class="text-center py-4">
          <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
          Loading...
        </td>
      </tr>
    `;
	}

	showError() {
		this.tbodyTarget.innerHTML = `
      <tr>
        <td colspan="${this.columnsValue.length}" class="text-center py-4 text-danger">
          Error loading data. Please try again.
        </td>
      </tr>
    `;
	}

	renderTable(data) {
		if (data.length === 0) {
			this.tbodyTarget.innerHTML = `
        <tr>
          <td colspan="${this.columnsValue.length}" class="text-center py-4">
            No records found
          </td>
        </tr>
      `;
			return;
		}

		this.tbodyTarget.innerHTML = data
			.map(
				(row) => `
        <tr>
          ${this.columnsValue
						.map((col) => `<td>${row[col.data] ?? ""}</td>`)
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

		// First and Previous buttons
		pages.push(`
      <li class="page-item ${this.currentPage === 0 ? "disabled" : ""}">
        <a class="page-link" href="#" data-action="admin-table#firstPage">&laquo;</a>
      </li>
      <li class="page-item ${this.currentPage === 0 ? "disabled" : ""}">
        <a class="page-link" href="#" data-action="admin-table#previousPage">&lsaquo;</a>
      </li>
    `);

		// Page numbers
		for (let i = startPage; i < endPage; i++) {
			pages.push(`
        <li class="page-item ${i === this.currentPage ? "active" : ""}">
          <a class="page-link" href="#" data-action="admin-table#goToPage" data-page="${i}">${
				i + 1
			}</a>
        </li>
      `);
		}

		// Next and Last buttons
		pages.push(`
      <li class="page-item ${
				this.currentPage >= this.totalPages - 1 ? "disabled" : ""
			}">
        <a class="page-link" href="#" data-action="admin-table#nextPage">&rsaquo;</a>
      </li>
      <li class="page-item ${
				this.currentPage >= this.totalPages - 1 ? "disabled" : ""
			}">
        <a class="page-link" href="#" data-action="admin-table#lastPage">&raquo;</a>
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
