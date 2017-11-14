class HeroComponent < MountainView::Presenter
  properties :title, :subtitle

  def title
    s = properties[:title]
    if s.length > 30
      s.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ').html_safe
    else
      s
    end
  end

  def subtitle
    properties[:subtitle]
  end
end
