require("@rails/ujs").start();
import "@hotwired/turbo-rails";

// Bootstrap still needed for some pages during migration
import "bootstrap";
import "./src/jquery";

// Input selectors - Cocoon for nested forms
require("@nathanvda/cocoon");
// Note: Select2 removed - now using Tom Select via Stimulus controller
// Note: DataTables removed - now using Stimulus admin_table_controller

// Cocoon callback to reinitialize Stimulus controllers on dynamically added elements
// Cocoon uses jQuery to clone and insert elements, which bypasses Stimulus's MutationObserver
$(document).on("cocoon:after-insert", function (e, insertedItem) {
	// Find all elements with data-controller in the inserted item and reinitialize them
	const controllers = insertedItem[0].querySelectorAll("[data-controller]");
	controllers.forEach((element) => {
		// Trigger a mutation that Stimulus will detect by removing and re-adding the attribute
		const controllerValue = element.getAttribute("data-controller");
		element.removeAttribute("data-controller");
		// Use requestAnimationFrame to ensure the DOM updates are processed
		requestAnimationFrame(() => {
			element.setAttribute("data-controller", controllerValue);
		});
	});
});

import "./controllers";
