class HeroComponent < MountainView::Presenter
  properties :title, :subtitle

  def title
    titleize(properties[:title])
  end

  def subtitle
    properties[:subtitle]
  end
end
