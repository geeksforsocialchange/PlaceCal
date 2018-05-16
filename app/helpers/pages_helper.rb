# frozen_string_literal: true

module PagesHelper
  def presentation_image(id, alt = '')
    "<img src='#{src(id)}' srcset='#{srcset(id)}' alt='#{alt}'>".html_safe
  end

  private

  def src(id)
    image_path("presentation/desktop/std-#{id}.png")
  end

  def srcset(id)
    [
      image_path("presentation/mobile/std-#{id}.png") + ' 600w',
      image_path("presentation/mobile/ret-#{id}.png") + ' 1200w',
      image_path("presentation/tablet/std-#{id}.png") + '  900w',
      image_path("presentation/tablet/ret-#{id}.png") + ' 1800w',
      image_path("presentation/desktop/std-#{id}.png") + '  1130w',
      image_path("presentation/desktop/ret-#{id}.png") + '  2260w'
    ].join(', ')
  end
end
