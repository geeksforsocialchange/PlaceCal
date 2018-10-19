# frozen_string_literal: true

class MapComponent < MountainView::Presenter
  properties :points, :zoom, :site

  # FIXME: Find out why this isn't working as a constant
  def api_token
    'pk.eyJ1IjoicGxhY2VjYWwiLCJhIjoiY2ptdzJqM3owMzN1bDNwbnhjbHIzb25layJ9.Kq2KjkWzSvLOpiHICuJiPA'
  end

  # FIXME: for some reason tests are returning [nil] from properties[:points]
  def markers
    properties[:points] == [nil] ? [] : properties[:points]
  end

  def center
    m = markers
    if m.nil? || m.empty?
      false
    elsif m.length > 1
      find_center(m)
    elsif m.length == 1
      [m[0][:lat], m[0][:lon]]
    end
  end

  def zoom
    properties[:zoom] || 16
  end

  def styles
    if properties[:style] == :full
      ' map--multiple'
    elsif properties[:style] == :single
      ' map--single'
    elsif markers.length > 1
      ' map--multiple'
    else
      ' map--single'
    end
  end

  # IDs from Mapbox
  def tileset
    case site
    when 'mossley'
      'cjmw2kdvt70g82snxpa2gqdza'
    else
      'cjmw2khle4d6q2sl7sqsvak2x'
    end
  end

  private

  def find_center(m)
    m.reject!(&:nil?)
    [
      m.map { |p| p[:lat] }.sum / m.length,
      m.map { |p| p[:lon] }.sum / m.length
    ]
  end
end
