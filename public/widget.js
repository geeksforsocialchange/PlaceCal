window.onload = function() {
  // Load params
  var widget = document.getElementById('placecal_widget');
  var place = widget.getAttribute('data-place');
  var limit = widget.getAttribute('data-limit');
  var width = widget.getAttribute('data-width') || 400;
  var height = widget.getAttribute('data-height') || 700;

  // Load iFrame
  var iframe = document.createElement('iframe');
  iframe.style.border = 'none';
  iframe.style.margin = 0;
  iframe.style.padding = 0;
  iframe.style.width = width;
  iframe.style.height = height;
  iframe.src = 'http://localhost:3000/places/' + place + '/embed';
  console.log(iframe);
  document.body.appendChild(iframe);
};