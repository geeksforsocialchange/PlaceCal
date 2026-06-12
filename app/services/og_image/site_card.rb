# frozen_string_literal: true

module OgImage
  # Subdomain site homepage card: the site's own identity with a
  # "Powered by PlaceCal" lockup to keep both identities. When the site
  # has a hero image it fills the background with the identity in a cream
  # panel on top; otherwise the type-only layout is used.
  class SiteCard < BaseCard
    PANEL_X = 64
    PANEL_Y = 64
    PANEL_WIDTH = 600
    PANEL_HEIGHT = HEIGHT - (PANEL_Y * 2)
    PANEL_PAD_X = 58
    PANEL_TEXT_WIDTH = PANEL_WIDTH - (PANEL_PAD_X * 2)

    def initialize(site)
      super()
      @site = site
    end

    private

    attr_reader :site

    def render
      return super if hero_path.blank?

      render_with_hero
    end

    # Full-bleed hero with a soft scrim for legibility and the identity
    # vertically centred in a rounded cream panel pinned left.
    def render_with_hero
      canvas = photo(hero_path, width: WIDTH, height: HEIGHT)
      canvas = composite(canvas, scrim, 0, 0)
      canvas = composite(canvas, panel, PANEL_X, PANEL_Y)

      pill_img = pill(t('labels.community_site'), accent, CREAM, size: 20, pad: 22, height: 40)
      title_img = text(title, size: 58, face: 'Trocchi', colour: BROWN, line_height: 1.03,
                              wrap_width: PANEL_TEXT_WIDTH, max_height: 220)
      row_imgs = rows.filter_map do |icon, value|
        next if value.blank?

        [icon_image(icon, size: 30),
         text(value, size: 26, face: 'Rawline SemiBold', colour: BROWN, max_width: PANEL_TEXT_WIDTH - 45)]
      end
      lockup = powered_by_lockup(logo_height: 32, opacity: 0.85)

      total = pill_img.height + 24 + title_img.height + 28 +
              (row_imgs.size * 45) - 15 + 34 + lockup.height
      x = PANEL_X + PANEL_PAD_X
      y = PANEL_Y + ((PANEL_HEIGHT - total) / 2)

      canvas = composite(canvas, pill_img, x, y)
      y += pill_img.height + 24
      canvas = composite(canvas, title_img, x, y)
      y += title_img.height + 28
      row_imgs.each do |icon_img, text_img|
        canvas = composite(canvas, icon_img, x, y)
        canvas = composite(canvas, text_img, x + 45, y + ((30 - text_img.height) / 2))
        y += 30 + 15
      end
      composite(canvas, lockup, x, y + 34 - 15)
    end

    # "POWERED BY" + logo as one transparent group, centre-aligned.
    def powered_by_lockup(logo_height:, opacity:)
      logo = svg_asset('logo-header.svg', height: logo_height)
      label_img = text(t('powered_by'), size: 19, face: 'Rawline ExtraBold',
                                        colour: ICON_BROWN, letter_spacing: 2)
      group = Vips::Image.black(label_img.width + 12 + logo.width, logo.height, bands: 4)
                         .copy(interpretation: :srgb)
      group = composite(group, label_img, 0, (logo.height - label_img.height) / 2)
      apply_opacity(composite(group, logo, label_img.width + 12, 0), opacity)
    end

    # linear-gradient(105deg, rgba(43,36,31,.34) 0%, .10 42%, transparent 64%)
    # expressed as an SVG gradient: CSS 105deg gives the direction vector
    # (sin 105, -cos 105), drawn here through the canvas centre.
    def scrim
      svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}">
          <defs>
            <linearGradient id="scrim" gradientUnits="userSpaceOnUse"
                            x1="-39" y1="144" x2="1239" y2="486">
              <stop offset="0" stop-color="rgb(43,36,31)" stop-opacity="0.34"/>
              <stop offset="0.42" stop-color="rgb(43,36,31)" stop-opacity="0.10"/>
              <stop offset="0.64" stop-color="rgb(43,36,31)" stop-opacity="0"/>
            </linearGradient>
          </defs>
          <rect width="#{WIDTH}" height="#{HEIGHT}" fill="url(#scrim)"/>
        </svg>
      SVG
    end

    def panel
      svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="#{PANEL_WIDTH}" height="#{PANEL_HEIGHT}">
          <rect width="#{PANEL_WIDTH}" height="#{PANEL_HEIGHT}" rx="24" fill="#{CREAM}"/>
        </svg>
      SVG
    end

    def hero_path
      path = site.hero_image&.opengraph&.path
      path if path.present? && File.exist?(path)
    end

    def label
      t('labels.site')
    end

    def label_colour
      CREAM
    end

    def title
      site.name
    end

    def accent
      ACCENTS[:site]
    end

    def rows
      [
        [:globe, domain],
        [:users, site.tagline]
      ]
    end

    def domain
      URI.parse(site.url).host || site.url
    rescue URI::InvalidURIError
      site.url
    end

    def compose_watermark(canvas)
      lockup = powered_by_lockup(logo_height: 34, opacity: 0.82)
      composite(canvas, lockup, WIDTH - 80 - lockup.width, HEIGHT - 60 - lockup.height)
    end
  end
end
