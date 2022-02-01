// This makes sure Turbolinks doesn't double load the datatable code
// if you press the browser back button
let dataTable = ""

document.addEventListener("turbolinks:before-cache", function () {
  if (dataTable !== null) {
      dataTable.destroy();
      dataTable = null;
  }
});

document.addEventListener('turbolinks:load', function () {
  try {
    dataTable = $('#datatable').DataTable({
      "processing": true,
      "serverSide": true,
      "pageLength": 15,
      "ajax": {
        "url": $('#datatable').data('source')
      },
      "pagingType": "full_numbers",
      // Column spec is loaded from a script tag in the view
      "columns": columns
    })
  } catch (e) {
    // On pages where DataTables shouldn't be used, columns is not defined.
    // This catches that and stops it throwing an error to the console.
    if (!(e instanceof ReferenceError)) {
      console.error(e);
    }
  }
});
