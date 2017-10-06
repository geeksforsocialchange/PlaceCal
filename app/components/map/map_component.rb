class MapComponent < MountainView::Presenter
  properties :points, :zoom

  def markers
    properties[:points]
  end

  def center
    m = markers
    m.length > 1 ? find_center(m) : [m[0][:lat], m[0][:lon]]
  end

  def zoom
    properties[:zoom] || 16
  end

  private

  def find_center(m)
    [
      m.map { |p| p[:lat] }.sum / m.length,
      m.map { |p| p[:lon] }.sum / m.length
    ]
  end
end
