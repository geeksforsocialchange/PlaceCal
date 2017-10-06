class MapComponent < MountainView::Presenter
  properties :points, :zoom

  def center
    m = markers
    m.length > 1 ? find_center(m) : m[0][:latlng]
  end

  def markers
    # Input: [x, y, name]
    # Output: [
    #           { latlng: [x, y], popup: 'hello', arbitrary: 'string' },
    #           { latlng: [x, y], popup: 'hello' }
    #         ]
    properties[:points].map { |p| { latlng: [p[0], p[1]] } }
  end

  def zoom
    properties[:zoom] || 16
  end

  private

  def find_center(m)
    [
      m.map { |p| p[:latlng][0] }.sum / m.length,
      m.map { |p| p[:latlng][1] }.sum / m.length
    ]
  end
end
