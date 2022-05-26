
module MapHelper
  API_TOKEN = 'pk.eyJ1IjoicGxhY2VjYWwiLCJhIjoiY2ptdzJqM3owMzN1bDNwbnhjbHIzb25layJ9.Kq2KjkWzSvLOpiHICuJiPA'

  def args_for_map(map_points, site)
    data_for_markers = map_points.dup.reject(&:nil?).map do |mrkr|
      {
        position: [mrkr[:lat], mrkr[:lon]],
        anchor: link_to(mrkr[:name], partner_path(mrkr[:id]))
        #id: mrkr[:id],
        #name: mrkr[:name]
      }
    end

    # payload
    {
      center: center(data_for_markers),
      zoom: 16,
      iconUrl: image_path('icons/map/map-marker.png'),
      shadowUrl: image_path('icons/map/map-shadow.png'),
      markers: data_for_markers,
      tilesetUrl: tileset_for_site_url(site)
    }.to_json.html_safe
  end

  def map_style_class(points)
    points.length > 1 ? ' map--multiple' : ' map--single'
  end

  private

  def center(marker_data)
    return false if marker_data.blank?
    return marker_data.first[:position] if marker_data.length == 1

    [
      marker_data.map { |p| p[:position][0] }.sum / marker_data.length,
      marker_data.map { |p| p[:position][1] }.sum / marker_data.length
    ]
  end


  def tileset_for_site_url(site)
    tileset = case site
              when 'moston'
                'cjwj3cf3m07wo1codspw72dnm'
              when 'mossley'
                'cjmw2kdvt70g82snxpa2gqdza'
              else
                'cjmw2khle4d6q2sl7sqsvak2x'
              end

    "https://api.mapbox.com/styles/v1/placecal/#{tileset}/tiles/256/{z}/{x}/{y}@2x?access_token=#{API_TOKEN}"
  end
end

