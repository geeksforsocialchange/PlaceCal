import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="image-preview"
export default class extends Controller {
	static targets = ["img"];

	connect() {}

	file(event) {
		const file = event.target.files[0];
		const reader = new FileReader();
		reader.onload = (e) => {
			const base64 = e.target.result;
			this.imgTarget.src = base64;
			this.imgTarget.style.display = "block";
		};
		reader.readAsDataURL(file);
	}
}
