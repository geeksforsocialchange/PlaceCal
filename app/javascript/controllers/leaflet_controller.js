import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="leaflet"
export default class extends Controller {
	static values = { args: Object };
	// {center, iconUrl, markers, shadowUrl, styleClass, tilesetUrl, zoom}
	connect() {
		console.log("connected");
		console.log(Object.keys(this.argsValue));
	}
}
