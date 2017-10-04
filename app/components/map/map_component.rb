class MapComponent < MountainView::Presenter
  properties :points, :zoom

  def center
    p = properties[:points][0]
    p.length > 1 ? properties[:points][0]
  end

  def markers
    # Input format: [x, y, name]
    # Target: [
    #           { latlng: [x, y], popup: 'hello' },
    #           { latlng: [x, y], popup: 'hello' }
    #         ]
    properties[:points].map { |p| { latlng: [p[0], p[1]] } }
  end

  def zoom
    properties[:zoom] || 16
  end
end