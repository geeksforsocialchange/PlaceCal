# frozen_string_literal: true

module OgImage
  class PartnerCard < BaseCard
    TAG_PILL_STYLES = [
      { bg: '#eef3df', border: '#d8e3b0' },
      { bg: '#f6efe2', border: '#e7dcc6' }
    ].freeze

    # Photo layout: text column left, square photo frame right.
    PHOTO_SIZE = 396
    PHOTO_RADIUS = 28
    PHOTO_COLUMN = 500
    PHOTO_TEXT_WIDTH = WIDTH - PADDING_X - PHOTO_COLUMN - 40

    def initialize(partner)
      super()
      @partner = partner
    end

    private

    attr_reader :partner

    def render
      return super if photo_path.blank?

      render_with_photo
    end

    # Two-column variant when the partner has a photo or logo on file:
    # details on the left, the image in a square rounded frame vertically
    # centred in a 500px right column.
    def render_with_photo
      canvas = background
      y = 80

      canvas = composite(canvas, pill(label, accent, label_colour), PADDING_X, y)
      y += PILL_HEIGHT + 24

      title_img = text(title, size: 56, face: 'Trocchi', colour: BROWN, line_height: 1.05,
                              wrap_width: PHOTO_TEXT_WIDTH, max_height: 190)
      canvas = composite(canvas, title_img, PADDING_X, y)
      y += title_img.height + 30

      photo_rows.each do |icon, value|
        next if value.blank?

        text_img = text(value, size: 26, face: 'Rawline SemiBold', colour: BROWN,
                               max_width: PHOTO_TEXT_WIDTH - 45)
        canvas = composite(canvas, icon_image(icon, size: 30), PADDING_X, y)
        canvas = composite(canvas, text_img, PADDING_X + 45, y + ((30 - text_img.height) / 2))
        y += 30 + 15
      end

      canvas = compose_tag_pills(canvas, left: PADDING_X, top: y + 24 - 15, size: 22)

      logo = svg_asset('logo-header.svg', height: 36, opacity: 0.82)
      canvas = composite(canvas, logo, PADDING_X, HEIGHT - 60 - logo.height)

      frame = photo(photo_path, width: PHOTO_SIZE, height: PHOTO_SIZE, radius: PHOTO_RADIUS)
      composite(canvas, frame, WIDTH - PHOTO_COLUMN + 24, (HEIGHT - PHOTO_SIZE) / 2)
    end

    def photo_path
      path = partner.image&.path
      path if path.present? && File.exist?(path)
    end

    def label
      t('labels.partner')
    end

    def title
      partner.name
    end

    def accent
      ACCENTS[:partner]
    end

    # Type-only card: full address and upcoming events.
    def rows
      [
        [:map_pin, partner.address&.to_s],
        [:calendar, upcoming_events_text]
      ]
    end

    # Photo card: shorter address plus the ward, so the text column stays tidy.
    def photo_rows
      [
        [:map_pin, short_address],
        [:map, ward],
        [:calendar, upcoming_events_text]
      ]
    end

    def short_address
      return nil unless partner.address

      [partner.address.street_address, partner.address.city].compact_blank.join(', ')
    end

    def ward
      neighbourhood = partner.address&.neighbourhood
      return nil unless neighbourhood

      [neighbourhood.shortname, neighbourhood.unit].compact_blank.join(' ')
    end

    def upcoming_events_text
      count = Event.by_organiser_or_place(partner).upcoming.count
      return nil if count.zero?

      t('upcoming_events', count: count)
    end

    def compose_content(canvas)
      compose_tag_pills(super, left: PADDING_X, top: @content_bottom + 30 - ROW_GAP, size: 23)
    end

    # Up to two category pills, 12px apart, in alternating pastel styles.
    def compose_tag_pills(canvas, left:, top:, size:)
      names = partner.categories.limit(2).map(&:name)
      return canvas if names.empty?

      names.each_with_index do |name, i|
        style = TAG_PILL_STYLES[i % TAG_PILL_STYLES.size]
        img = tag_pill(name, style, size: size)
        canvas = composite(canvas, img, left, top)
        left += img.width + 12
      end
      canvas
    end

    def tag_pill(name, style, size:)
      label_img = text(name, size: size, face: 'Rawline', weight: 'bold', colour: BROWN)
      width = label_img.width + 44
      height = size + 20
      bar = svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">
          <rect x="1" y="1" width="#{width - 2}" height="#{height - 2}" rx="#{(height / 2) - 1}"
                fill="#{style[:bg]}" stroke="#{style[:border]}" stroke-width="2"/>
        </svg>
      SVG
      composite(bar, label_img, 22, ((height - label_img.height) / 2.0).round)
    end
  end
end
