# frozen_string_literal: true

class MapPreview < Lookbook::Preview
  # @label With multiple points
  def with_points
    points = [
      { lat: 53.4631, lon: -2.2496, name: "Hulme Community Garden", url: "/partners/1" },
      { lat: 53.4601, lon: -2.2480, name: "Moss Side Leisure Centre", url: "/partners/2" },
      { lat: 53.4650, lon: -2.2530, name: "Zion Arts Centre", url: "/partners/3" }
    ]
    render Components::Map.new(points: points, site: "default-site")
  end

  # @label Single point
  def single_point
    points = [
      { lat: 53.4631, lon: -2.2496, name: "Hulme Community Garden", url: "/partners/1" }
    ]
    render Components::Map.new(points: points, site: "default-site")
  end

  # @label Empty (no points)
  def empty
    render Components::Map.new(points: [], site: "default-site")
  end
end
