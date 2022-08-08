import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="leaflet"
// Its important to use single quotes in the template when declaring the args values
// data-leaflet-args-value='<%= args_for_map(points, site, local_assigns[:style], local_assigns[:compact]) %>'
// If not you will get strange unicode values which will break parsing
export default class extends Controller {
	static values = { args: Object };
	// {center, iconUrl, markers, shadowUrl, styleClass, tilesetUrl, zoom}
	connect() {
		console.log("connected");
		console.log(Object.keys(this.argsValue));
	}
}
