# frozen_string_literal: true

module MapHelper
  def args_for_map(map_points, site, style_mode, compact_mode)
    data_for_markers = map_points.dup.reject(&:nil?).map do |mrkr|
      {}.tap do |pin|
        pin[:position] = [mrkr[:lat], mrkr[:lon]]
        pin[:anchor] = link_to(mrkr[:name], partner_path(mrkr[:id]), data: { turbo_frame: '_top' }) if mrkr[:id]
      end
    end

    # payload
    {
      center: center(data_for_markers),
      zoom: 16,
      iconUrl: image_path('icons/map/map-marker.png'),
      shadowUrl: image_path('icons/map/map-shadow.png'),
      markers: data_for_markers,
      styleUrl: style_url_for_site(site),
      styleClass: map_style_class(data_for_markers, style_mode, compact_mode)
    }.to_json.html_safe
  end

  private

  def map_style_class(points, style_mode, compact_mode)
    out = []
    out << case style_mode
           when :single
             'map--single'
           when :multi
             'map--multiple'
           else
             (points.length > 1 ? 'map--multiple' : 'map--single')
           end
    out << 'map--compact' if compact_mode
    out
  end

  def center(marker_data)
    return false if marker_data.blank?
    return marker_data.first[:position] if marker_data.length == 1

    [
      marker_data.sum { |p| p[:position][0] } / marker_data.length,
      marker_data.sum { |p| p[:position][1] } / marker_data.length
    ]
  end

  # Returns the URL to a themed MapLibre style JSON file
  # Uses OpenFreeMap vector tiles with custom colors matching site themes
  def style_url_for_site(site)
    # site can be a Site object or a slug string
    site_record = site.is_a?(Site) ? site : Site.find_by(slug: site)

    style_name = if site_record.nil?
                   'pink'
                 elsif site_record.theme.to_s == 'custom'
                   # Custom themed sites use their slug (e.g., 'mossley')
                   site_record.slug
                 else
                   site_record.theme.to_s
                 end

    # Fall back to pink if style file doesn't exist
    style_path = Rails.public_path.join('map-styles', "#{style_name}.json")
    style_name = 'pink' unless File.exist?(style_path)

    "/map-styles/#{style_name}.json"
  end
end
