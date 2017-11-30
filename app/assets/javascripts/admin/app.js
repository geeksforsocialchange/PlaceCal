$(document).ready(function() {
  $(".starting-datetimepicker").datetimepicker({
    debug: false,
    format: "YYYY-MM-DD"
  });

  $(".field-unit__field.select-search select").selectize({});
});
