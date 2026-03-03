# frozen_string_literal: true

class Views::Admin::Pages::Icons < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  prop :icons, Hash, reader: :private

  ICON_CATEGORIES = {
    'Actions' => %i[trash plus check edit x upload external_link logout cog swap eye eye_off bell],
    'Navigation' => %i[home chevron_right chevron_left],
    'Status / Alerts' => %i[crown warning info lightning check_circle x_circle],
    'Content Types' => %i[partner calendar site event user photo article partnership tag neighbourhood],
    'People' => %i[users user_add],
    'Location' => %i[location map_pin],
    'Communication' => %i[chat link mail],
    'Resources' => %i[book clipboard desktop newspaper list credit_card bug map code],
    'Social' => %i[website facebook twitter instagram],
    'Form' => %i[form_checkbox form_checkbox_check form_cross form_radio form_radio_check form_tick],
    'Triangle' => %i[triangle_up triangle_down triangle_left triangle_right],
    'Event' => %i[event_date event_duration event_place event_repeats event_time],
    'Contact' => %i[contact_email contact_facebook contact_instagram contact_instagram_circle contact_phone
                    contact_twitter contact_website],
    'Misc' => %i[misc_menu misc_place misc_question_mark misc_repeats misc_roundel misc_time],
    'Home' => %i[home_quote_open home_quote_close home_slide home_minus home_plus]
  }.freeze

  def view_template
    content_for(:title) { 'Icon Reference' }
    render_header
    render_categories
    render_divider
    render_size_reference
    render_stroke_reference
    render_color_examples
    render_helper_location
  end

  private

  def render_header # rubocop:disable Metrics/AbcSize
    div(class: 'mb-6') do
      h1(class: 'text-2xl font-bold') { 'Icon Reference' }
      p(class: 'text-sm text-gray-600 mt-1') do
        plain "All #{SvgIconsHelper::ICONS.count} icons available via the "
        code(class: 'bg-base-200 px-1 rounded') { 'icon()' }
        plain ' helper. Usage: '
        code(class: 'bg-base-200 px-1 rounded') { raw safe("<%= icon(:name, size: '5', css_class: 'text-red-500 stroke-3') %>") }
        plain ' For non-admin frontend, prefer to use '
        code(class: 'bg-base-200 px-1 rounded') { 'size: nil' }
        plain ' (unsized) and style with CSS.'
      end
    end
  end

  def render_categories
    div(class: 'space-y-8') do
      ICON_CATEGORIES.each do |category, icon_names|
        render_category(category, icon_names)
      end
    end
  end

  def render_category(category, icon_names) # rubocop:disable Metrics/AbcSize
    div(class: 'card bg-base-100 border border-base-300') do
      div(class: 'card-body p-4') do
        h2(class: 'font-bold text-lg mb-4 flex items-center gap-2') do
          span(class: 'w-2 h-2 rounded-full bg-placecal-orange')
          plain category
          span(class: 'badge badge-ghost badge-sm') { icon_names.count.to_s }
        end
        div(class: 'grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4') do
          icon_names.each { |name| render_icon_tile(name) if SvgIconsHelper::ICONS[name] }
        end
      end
    end
  end

  def render_icon_tile(icon_name)
    div(class: 'flex flex-col items-center p-3 rounded-lg bg-base-200/50 hover:bg-base-200 transition-colors group') do
      div(class: 'w-12 h-12 flex items-center justify-center rounded-lg bg-base-100 border border-base-300 mb-2 ' \
                 'group-hover:border-placecal-orange transition-colors') do
        icon(icon_name, size: '6')
      end
      code(class: 'text-xs font-mono text-base-content/70 group-hover:text-placecal-orange transition-colors') do
        plain ":#{icon_name}"
      end
    end
  end

  def render_divider
    div(class: 'divider my-8')
  end

  def render_size_reference # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300 mb-8') do
      div(class: 'card-body p-4') do
        h2(class: 'font-bold text-lg mb-4') { 'Size Reference' }
        p(class: 'text-sm text-gray-600 mb-4') do
          plain 'Use the '
          code(class: 'bg-base-200 px-1 rounded') { 'size' }
          plain " parameter to control icon dimensions. Maps to Tailwind's "
          code(class: 'bg-base-200 px-1 rounded') { 'size-{n}' }
          plain ' utility.'
        end
        div(class: 'flex flex-wrap items-end gap-6') do
          [3, 4, 5, 6, 8, 10, 12].each do |size|
            div(class: 'flex flex-col items-center') do
              div(class: 'flex items-center justify-center p-2 rounded-lg bg-base-200/50 mb-2') do
                icon(:calendar, size: size.to_s)
              end
              code(class: 'text-xs font-mono text-gray-600') { "size: '#{size}'" }
            end
          end
        end
      end
    end
  end

  def render_stroke_reference # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 border border-base-300 mb-8') do
      div(class: 'card-body p-4') do
        h2(class: 'font-bold text-lg mb-4') { 'Stroke Width Reference' }
        p(class: 'text-sm text-gray-600 mb-4') do
          plain 'Use the '
          code(class: 'bg-base-200 px-1 rounded') { 'css_class' }
          plain ' parameter to add Tailwind stroke-width classes to control line thickness. ' \
                "Default is '2'. Enclose non-integer values in square brackets."
        end
        div(class: 'flex flex-wrap items-end gap-6') do
          %w[stroke-1 stroke-[1.5] stroke-2 stroke-[2.5] stroke-3].each do |sw|
            div(class: 'flex flex-col items-center') do
              div(class: 'flex items-center justify-center p-2 rounded-lg bg-base-200/50 mb-2') do
                icon(:calendar, size: '8', css_class: sw)
              end
              code(class: 'text-xs font-mono text-gray-600') { "'#{sw}'" }
            end
          end
        end
      end
    end
  end

  def render_color_examples # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    colors = [
      ['text-placecal-orange', 'PlaceCal Orange'], ['text-success', 'Success'], ['text-error', 'Error'],
      ['text-warning', 'Warning'], ['text-info', 'Info'], ['text-gray-600', '50% opacity']
    ]

    div(class: 'card bg-base-100 border border-base-300') do
      div(class: 'card-body p-4') do
        h2(class: 'font-bold text-lg mb-4') { 'Color Examples' }
        p(class: 'text-sm text-gray-600 mb-4') do
          plain 'Use the '
          code(class: 'bg-base-200 px-1 rounded') { 'css_class' }
          plain ' parameter to add Tailwind color classes. Icons inherit color via '
          code(class: 'bg-base-200 px-1 rounded') { 'stroke="currentColor"' }
          plain ' or '
          code(class: 'bg-base-200 px-1 rounded') { 'fill="currentColor"' }
          plain '.'
        end
        div(class: 'flex flex-wrap items-end gap-6') do
          colors.each do |css_class, label_text|
            div(class: 'flex flex-col items-center') do
              div(class: 'flex items-center justify-center p-2 rounded-lg bg-base-200/50 mb-2') do
                icon(:check_circle, size: '8', css_class: css_class)
              end
              code(class: 'text-xs font-mono text-gray-600') { "'#{css_class}'" }
              p(class: 'text-xs mt-1') { label_text }
            end
          end
        end
      end
    end
  end

  def render_helper_location
    div(class: 'mt-8 p-4 bg-base-200/50 rounded-lg') do
      h3(class: 'font-semibold mb-2') { 'Helper Location' }
      p(class: 'text-sm text-base-content/70') do
        plain 'Icons are defined in '
        code(class: 'bg-base-200 px-1 rounded') { 'app/helpers/svg_icons_helper.rb' }
        plain '. To add a new icon, add its SVG path data to the '
        code(class: 'bg-base-200 px-1 rounded') { 'ICONS' }
        plain ' hash.'
      end
    end
  end
end
