# frozen_string_literal: true

class Components::Shared::Map < Components::Base
  register_value_helper :args_for_map
  register_value_helper :map_layout

  theme_scope :map,
              parts: { root: 'The map. The variant says whether it shows one place, boxed, or several at full height.' },
              variants: { root: %i[single multiple] },
              tokens: %i[]

  prop :points, _Nilable(Array)
  prop :style, _Nilable(Symbol), default: nil
  prop :compact, _Boolean, default: false

  def view_template
    return if @points.blank?

    layout = map_layout(@points, @style)
    div(**part(:root, variant: layout, role: 'region', aria_label: label(layout),
                      class: @compact ? 'min-h-(--height-map-compact)' : 'min-h-(--height-map-full)',
                      data: { controller: 'leaflet', leaflet_args_value: args_for_map(@points, @style, @compact) }))
  end

  private

  def label(layout)
    name = @points.compact.first&.dig(:name)
    return t('components.map.places') if layout == :multiple
    return t('components.map.label') if name.blank?

    t('components.map.place', name:)
  end
end
