# frozen_string_literal: true

class MapComponent < MountainView::Presenter
  # include ActionView::Helpers::AssetUrlHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::AssetTagHelper

  properties :points, :zoom, :site

  def args_for_map
    data_for_markers = markers.map do |mrkr|
      {
        position: [mrkr[:lat], mrkr[:lon]],
        anchor: link_to(mrkr[:name], "/partners/#{(mrkr[:id])}")
        #id: mrkr[:id],
        #name: mrkr[:name]
      }
    end

    tileset_url = "https://api.mapbox.com/styles/v1/placecal/#{tileset}/tiles/256/{z}/{x}/{y}@2x?access_token=#{api_token}"

    # payload
    {
      center: center,
      zoom: zoom,
      iconUrl: asset_tag('icons/map/map-marker.png'),
      shadowUrl: asset_tag('icons/map/map-shadow.png'),
      markers: data_for_markers,
      tilesetUrl: tileset_url
    }.to_json.html_safe
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

  private

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


  # TODO: Hook in to new themes
  # IDs from Mapbox
  def tileset
    case site
    when 'moston'
      'cjwj3cf3m07wo1codspw72dnm'
    when 'mossley'
      'cjmw2kdvt70g82snxpa2gqdza'
    else
      'cjmw2khle4d6q2sl7sqsvak2x'
    end
  end

  def find_center(m)
    m.reject!(&:nil?)
    [
      m.map { |p| p[:lat] }.sum / m.length,
      m.map { |p| p[:lon] }.sum / m.length
    ]
  end
end
