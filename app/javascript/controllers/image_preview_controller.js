import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="image-preview"
export default class extends Controller {
	static targets = ["img", "dropzone", "input", "placeholder"];

	connect() {
		if (this.hasDropzoneTarget) {
			this.dropzoneTarget.addEventListener(
				"dragover",
				this.dragOver.bind(this)
			);
			this.dropzoneTarget.addEventListener(
				"dragleave",
				this.dragLeave.bind(this)
			);
			this.dropzoneTarget.addEventListener("drop", this.drop.bind(this));
		}
	}

	disconnect() {
		if (this.hasDropzoneTarget) {
			this.dropzoneTarget.removeEventListener(
				"dragover",
				this.dragOver.bind(this)
			);
			this.dropzoneTarget.removeEventListener(
				"dragleave",
				this.dragLeave.bind(this)
			);
			this.dropzoneTarget.removeEventListener("drop", this.drop.bind(this));
		}
	}

	dragOver(event) {
		event.preventDefault();
		event.stopPropagation();
		this.dropzoneTarget.classList.add(
			"border-placecal-orange",
			"bg-placecal-orange/5"
		);
		this.dropzoneTarget.classList.remove("border-base-300");
	}

	dragLeave(event) {
		event.preventDefault();
		event.stopPropagation();
		this.dropzoneTarget.classList.remove(
			"border-placecal-orange",
			"bg-placecal-orange/5"
		);
		this.dropzoneTarget.classList.add("border-base-300");
	}

	drop(event) {
		event.preventDefault();
		event.stopPropagation();
		this.dropzoneTarget.classList.remove(
			"border-placecal-orange",
			"bg-placecal-orange/5"
		);
		this.dropzoneTarget.classList.add("border-base-300");

		const files = event.dataTransfer.files;
		if (files.length > 0 && files[0].type.startsWith("image/")) {
			// Update the file input
			if (this.hasInputTarget) {
				const dataTransfer = new DataTransfer();
				dataTransfer.items.add(files[0]);
				this.inputTarget.files = dataTransfer.files;
			}
			// Show preview
			this.showPreview(files[0]);
		}
	}

	file(event) {
		const file = event.target.files[0];
		if (file) {
			this.showPreview(file);
		}
	}

	showPreview(file) {
		const reader = new FileReader();
		reader.onload = (e) => {
			const base64 = e.target.result;
			this.imgTarget.src = base64;
			this.imgTarget.style.display = "block";
			// Hide placeholder if exists
			if (this.hasPlaceholderTarget) {
				this.placeholderTarget.style.display = "none";
			}
		};
		reader.readAsDataURL(file);
	}
}
