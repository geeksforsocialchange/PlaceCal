require("@rails/ujs").start();
import "@hotwired/turbo-rails";

import "bootstrap";
import "./src/jquery";

// Input selectors
require("@nathanvda/cocoon");
require("select2")(window, $);

// Note: DataTables removed - now using Stimulus admin_table_controller

$(document).on("turbo:load", function () {
	$("[data-toggle='tooltip']").tooltip();
});

import "./controllers";
