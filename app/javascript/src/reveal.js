document.addEventListener('turbolinks:load',  () => {
  const eles = document.getElementsByClassName('js-reveal')
  for (let i = 0; i < eles.length; i++) {
    let ele = eles[i]
    let body = ele.getElementsByClassName('reveal__body')[0]
    let btn = ele.getElementsByClassName('reveal__button')[0]
    let isVisible = false

    ele.classList.toggle('is-hidden')
    btn.addEventListener('click', function(e) {
       e.preventDefault();
       isVisible = !isVisible
       ele.classList.toggle('is-hidden')
       if(isVisible) {
         btn.innerHTML = 'Close'
       } else {
         btn.innerHTML = 'Open to read more'
       }
     })
  }
})
