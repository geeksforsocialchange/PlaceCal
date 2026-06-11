# frozen_string_literal: true

module OgImage
  class PartnerCard < BaseCard
    TAG_PILL_STYLES = [
      { bg: '#eef3df', border: '#d8e3b0' },
      { bg: '#f6efe2', border: '#e7dcc6' }
    ].freeze

    def initialize(partner)
      super()
      @partner = partner
    end

    private

    attr_reader :partner

    def label
      t('labels.partner')
    end

    def title
      partner.name
    end

    def accent
      ACCENTS[:partner]
    end

    def rows
      [
        [:map_pin, partner.address&.to_s],
        [:calendar, upcoming_events_text]
      ]
    end

    def upcoming_events_text
      count = Event.by_organiser_or_place(partner).upcoming.count
      return nil if count.zero?

      t('upcoming_events', count: count)
    end

    def compose_content(canvas)
      compose_tag_pills(super)
    end

    # Up to two category pills below the detail rows (30px clearance,
    # 12px apart), in alternating pastel styles.
    def compose_tag_pills(canvas)
      names = partner.categories.limit(2).map(&:name)
      return canvas if names.empty?

      y = @content_bottom + 30 - ROW_GAP
      x = PADDING_X
      names.each_with_index do |name, i|
        style = TAG_PILL_STYLES[i % TAG_PILL_STYLES.size]
        img = tag_pill(name, style)
        canvas = composite(canvas, img, x, y)
        x += img.width + 12
      end
      canvas
    end

    def tag_pill(name, style)
      label_img = text(name, size: 23, face: 'Rawline', weight: 'bold', colour: BROWN)
      width = label_img.width + 44
      height = 43
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
