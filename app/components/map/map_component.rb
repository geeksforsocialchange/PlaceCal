class MapComponent < MountainView::Presenter
  properties :points, :zoom

  def markers
    # FIXME: for some reason tests are returning [nil] from properties[:points]
    properties[:points] == [nil] ? [] : properties[:points]
  end

  def center
    m = markers
    if m.length > 1
      find_center(m)
    elsif m.length == 1
      [m[0][:lat], m[0][:lon]]
    else
      false
    end
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
