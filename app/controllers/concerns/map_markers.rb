module MapMarkers

  # Takes an array of Partners and/or Addresses and returns a sanitized json
  # array suitable for creating map markers. Does not check for duplicates.
  def get_map_markers(locations)
    locations.reduce([]) do |arr, loc|
      marker =
        if (Partner == loc.class) && (loc&.address&.latitude)
          {
            lat: loc.address.latitude,
            lon: loc.address.longitude,
            name: loc.name,
            id: loc.id
          }
        elsif loc.class == Address
          {
            lat: loc.latitude,
            lon: loc.longitude
          }
        end
      if marker then arr << marker else arr end
    end
  end

  # Takes a reducible collection of events and returns json map markers.
  # Removes duplicate locations.
  def get_map_markers_from_events(events)
    get_map_markers(
      @events.reduce([]) do |arr, e|
        loc = e.place || e.address
        if loc then arr << loc else arr end
      end.uniq
    )
  end
end
