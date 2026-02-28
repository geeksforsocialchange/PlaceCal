# frozen_string_literal: true

class Components::Map < Components::Base
  register_value_helper :args_for_map

  prop :points, _Nilable(Array)
  prop :site, String
  prop :style, _Nilable(Symbol), default: nil
  prop :compact, _Boolean, default: false

  def view_template
    return if @points.blank?

    div(
      data_controller: 'leaflet',
      data_leaflet_args_value: args_for_map(@points, @site, @style, @compact)
    )
  end
end
