# frozen_string_literal: true

class HeroComponent < MountainView::Presenter
  def title
    s = properties[:title]
    if s.respond_to?(:length) && s.length > 32
      s.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ').html_safe
    else
      s
    end
  end

  def subtitle
    properties[:subtitle]&.length&.positive? ? properties[:subtitle] : false
  end
end
