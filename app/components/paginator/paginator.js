function updateButtons() {
  var buttons = $('.paginator__buttons li.button')
  var right_threshold = $('.paginator__buttons li.forwards').position().left - 30

  buttons.show()
  buttons.each(function(idx, ele) {
    var li = $(ele)
    var rhs = li.position().left + li.width();
    if(rhs >= right_threshold) {
      li.hide()
    } 
  })
}

$(document).on('turbolinks:load', function() {
  updateButtons()
})

var resizeTimer;

$(window).on('resize', function(e) {
  clearTimeout(resizeTimer)
  resizeTimer = setTimeout(function() {
    updateButtons()
  }, 100)
});