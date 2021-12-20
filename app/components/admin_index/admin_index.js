jQuery(document).ready(function() {
  $('#neighbourhood').dataTable({
    "processing": true,
    "serverSide": true,
    "ajax": {
      "url": $('#neighbourhood').data('source')
    },
    "pagingType": "full_numbers",
    "columns": [
      {"data": "id"},
      {"data": "name"},
      {"data": "county"},
      {"data": "district"},
      {"data": "region"},
      {"data": "country"}
    ]
  });
});
