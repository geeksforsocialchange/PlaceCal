# frozen_string_literal: true

module NeighbourhoodsHelper
  # Colour classes for neighbourhood levels (rainbow order: red → orange → green → blue → violet)
  # Used in datatables, badges, and hierarchy displays
  LEVEL_COLOURS = {
    5 => 'bg-rose-100 text-rose-700',     # country - red
    4 => 'bg-orange-100 text-orange-700', # region - orange
    3 => 'bg-emerald-100 text-emerald-700', # county - green
    2 => 'bg-sky-100 text-sky-700',       # district - blue
    1 => 'bg-violet-100 text-violet-700'  # ward - violet
  }.freeze

  DEFAULT_COLOUR = 'bg-gray-100 text-gray-700'

  # Get colour classes for a neighbourhood level (Integer) or unit (String)
  def neighbourhood_colour(level_or_unit)
    level = level_or_unit.is_a?(Integer) ? level_or_unit : Neighbourhood::LEVELS[level_or_unit&.to_sym]
    LEVEL_COLOURS[level] || DEFAULT_COLOUR
  end

  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end

  def safe_neighbourhood_name(neighbourhood)
    return neighbourhood.name if neighbourhood.name.present?

    "[untitled #{neighbourhood.id}]"
  end

  # Render a stylized level badge that looks like an icon
  # Circular, compact, with the level number prominent
  def level_badge(level, size: :default)
    size_classes = {
      small: 'w-5 h-5 text-[10px]',
      default: 'w-6 h-6 text-xs',
      large: 'w-7 h-7 text-sm'
    }.fetch(size, 'w-6 h-6 text-xs')

    colour = LEVEL_COLOURS[level] || DEFAULT_COLOUR

    content_tag(:span, "L#{level}", class: "inline-flex items-center justify-center #{size_classes} rounded-full font-bold #{colour}")
  end

  def link_to_neighbourhood(neighbourhood)
    text = neighbourhood.name
    text += " - (#{neighbourhood.release_date.year}/#{neighbourhood.release_date.month})" if neighbourhood.legacy_neighbourhood?

    html = link_to(text, edit_admin_neighbourhood_path(neighbourhood))
    html.html_safe # rubocop:disable Rails/OutputSafety
  end
end
