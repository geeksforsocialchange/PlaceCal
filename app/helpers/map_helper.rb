# frozen_string_literal: true

module MapHelper
  def args_for_map(map_points, style_mode, compact_mode)
    data_for_markers = map_points.dup.reject(&:nil?).map do |mrkr|
      {}.tap do |pin|
        pin[:position] = [mrkr[:lat], mrkr[:lon]]
        pin[:anchor] = link_to(mrkr[:name], partner_path(mrkr[:id]), data: { turbo_frame: '_top', turbo_action: 'replace' }) if mrkr[:id]
      end
    end

    # payload
    {
      center: center(data_for_markers),
      zoom: 16,
      iconUrl: image_path('icons/map/map-marker.png'),
      shadowUrl: image_path('icons/map/map-shadow.png'),
      markers: group_colocated_markers(data_for_markers),
      styleUrl: map_style_url,
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

  def group_colocated_markers(markers)
    markers.group_by { |m| m[:position] }.map do |position, group|
      next group.first if group.length == 1

      anchors = group.filter_map { |m| m[:anchor] }
      merged = { position: position }
      merged[:anchor] = safe_join(anchors, tag.br) if anchors.any?
      merged
    end
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
  def map_style_url
    # The request's theme resolves the style name. The directory and sites
    # with an unregistered theme fall back to pink.
    style_name = Current.theme.map_style_name || 'pink'

    # A style ships either in core's public/map-styles or, for extensions, as
    # an asset at map-styles/<name>.json (e.g. app/assets/builds/map-styles/).
    # Fall back to pink if neither exists.
    return "/map-styles/#{style_name}.json" if Rails.public_path.join('map-styles', "#{style_name}.json").exist?

    asset = Rails.application.assets&.resolver&.resolve("map-styles/#{style_name}.json")
    asset || '/map-styles/pink.json'
  end
end
