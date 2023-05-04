$(document).on("turbo:load", function () {
	// Toggle the sort criteria
	$(".js-filters-toggle").on("click", function (event) {
		event.preventDefault();
		$(".js-filters-dropdown").toggle();
	});

	// When a radio changes, update the sort
	$(".js-filters-form :input").on("change", function () {
		$(".js-filters-form").submit();
	});
});
