# frozen_string_literal: true

require 'vips'

module OgImage
  # Bump to invalidate cached cards when the design changes.
  VERSION = 3

  # Renders 1200x630 Open Graph share card PNGs with libvips.
  #
  # Layout system (from the PlaceCal OG design handoff, issue #2077):
  # a cream canvas with a colour-coded category pill, a Trocchi title,
  # icon + text detail rows and the PlaceCal logo as a bottom-right
  # watermark. Subclasses supply content via #label, #title, #rows etc.
  #
  # Site-backed cards (Site, Partnership) also share an optional hero-image
  # background layout here, opted into by overriding #hero_path.
  # rubocop:disable Metrics/ClassLength -- cohesive drawing helpers + hero layout
  class BaseCard
    WIDTH = 1200
    HEIGHT = 630

    CREAM = '#fffbef'
    BROWN = '#5b4e46'
    ICON_BROWN = '#998675'

    ACCENTS = {
      event: '#afcf5a',
      partner: '#f19089',
      partnership: '#a3d7df',
      site: '#da65fd',
      page: '#f1e9da'
    }.freeze

    PADDING_X = 90
    PADDING_TOP = 84
    PILL_HEIGHT = 44
    TITLE_MAX_WIDTH = 1000
    TITLE_MAX_HEIGHT = 240
    ROW_ICON_SIZE = 32
    ROW_ICON_GAP = 16
    ROW_GAP = 17
    META_MAX_WIDTH = WIDTH - (PADDING_X * 2) - ROW_ICON_SIZE - ROW_ICON_GAP

    # Hero-background layout (site-backed cards): the hero fills the canvas
    # behind a scrim with the identity in a rounded cream panel pinned left.
    PANEL_X = 64
    PANEL_Y = 64
    PANEL_WIDTH = 600
    PANEL_HEIGHT = HEIGHT - (PANEL_Y * 2)
    PANEL_PAD_X = 58
    PANEL_TEXT_WIDTH = PANEL_WIDTH - (PANEL_PAD_X * 2)

    ASSETS_DIR = Rails.root.join('app/assets/images/og')

    # Feather-style icons matching the event page detail set.
    ICON_PATHS = {
      clock: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
      calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/>' \
                '<line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>',
      map_pin: '<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>',
      users: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>' \
             '<path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
      globe: '<circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>' \
             '<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>',
      map: '<polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/>' \
           '<line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/>'
    }.freeze

    def to_png
      render.write_to_buffer('.png')
    end

    private

    def render
      return render_with_hero if hero_path.present?

      canvas = background
      canvas = compose_content(canvas)
      compose_watermark(canvas)
    end

    # Full-bleed hero with a soft scrim for legibility and the identity
    # vertically centred in a rounded cream panel pinned left. Opted into by
    # site-backed subclasses that override #hero_path.
    def render_with_hero
      canvas = photo(hero_path, width: WIDTH, height: HEIGHT)
      canvas = composite(canvas, scrim, 0, 0)
      canvas = composite(canvas, panel, PANEL_X, PANEL_Y)

      pill_img = pill(label, accent, label_colour, size: 20, pad: 22, height: 40)
      title_img = text(title, size: 58, face: 'Trocchi', colour: BROWN, line_height: 1.03,
                              wrap_width: PANEL_TEXT_WIDTH, max_height: 220)
      row_imgs = rows.filter_map do |icon, value|
        next if value.blank?

        [icon_image(icon, size: 30),
         text(value, size: 26, face: 'Rawline SemiBold', colour: BROWN, max_width: PANEL_TEXT_WIDTH - 45)]
      end
      lockup = hero_lockup

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

    # Path to a full-bleed hero image, or nil for the type-only layout.
    def hero_path
      nil
    end

    # Branding pinned to the bottom of the hero panel. Defaults to the
    # "Powered by PlaceCal" lockup; PlaceCal-native cards use the bare logo.
    def hero_lockup
      powered_by_lockup(logo_height: 32, opacity: 0.85)
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

    def background
      colour = hex_to_rgb(CREAM)
      Vips::Image.black(WIDTH, HEIGHT, bands: 3).new_from_image(colour).copy(interpretation: :srgb)
                 .bandjoin(255)
    end

    def compose_content(canvas)
      y = PADDING_TOP

      pill_img = pill(label, accent, label_colour)
      canvas = composite(canvas, pill_img, PADDING_X, y)
      y += PILL_HEIGHT + 28

      title_img = title_text(title)
      canvas = composite(canvas, title_img, PADDING_X, y)
      y += title_img.height + 36

      rows.each do |icon, value|
        next if value.blank?

        icon_img = icon_image(icon)
        text_img = text(value, size: 28, face: 'Rawline SemiBold', colour: BROWN, max_width: META_MAX_WIDTH)
        canvas = composite(canvas, icon_img, PADDING_X, y)
        canvas = composite(canvas, text_img, PADDING_X + ROW_ICON_SIZE + ROW_ICON_GAP,
                           y + ((ROW_ICON_SIZE - text_img.height) / 2))
        y += ROW_ICON_SIZE + ROW_GAP
      end
      @content_bottom = y

      canvas
    end

    def compose_watermark(canvas)
      logo = svg_asset('logo-header.svg', height: 38, opacity: 0.82)
      composite(canvas, logo, WIDTH - 80 - logo.width, HEIGHT - 62 - logo.height)
    end

    # ==== Content supplied by subclasses ====

    def label
      raise NotImplementedError
    end

    def title
      raise NotImplementedError
    end

    # @return [Array<[Symbol, String]>] icon name / text pairs
    def rows
      []
    end

    def accent
      raise NotImplementedError
    end

    def label_colour
      BROWN
    end

    # ==== Drawing helpers ====

    # Category pill: extrabold uppercase with 2.5px tracking on a rounded bar.
    # rubocop:disable Metrics/ParameterLists -- keyword args mirroring CSS pill properties
    def pill(text_value, background, foreground, size: 22, pad: 24, height: PILL_HEIGHT)
      label_img = text(text_value.upcase, size: size, face: 'Rawline ExtraBold', colour: foreground,
                                          letter_spacing: 2.5)
      width = label_img.width + (pad * 2)
      bar = svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">
          <rect width="#{width}" height="#{height}" rx="#{height / 2}" fill="#{background}"/>
        </svg>
      SVG
      composite(bar, label_img, pad, ((height - label_img.height) / 2.0).round)
    end
    # rubocop:enable Metrics/ParameterLists

    # Load an uploaded photo as an opaque width x height tile with optional
    # rounded corners applied through an alpha mask.
    # - fit: :cover (default) crops to fill, for full-bleed photos.
    # - fit: :contain shrinks the whole image to fit on a cream tile, so
    #   wide logos stay intact instead of being cropped (matches the site).
    def photo(path, width:, height:, radius: nil, fit: :cover)
      img = fitted_photo(path, width: width, height: height, fit: fit)
      return img.bandjoin(255) unless radius

      mask = svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">
          <rect width="#{width}" height="#{height}" rx="#{radius}" fill="#fff"/>
        </svg>
      SVG
      img.bandjoin(mask[3])
    end

    # Returns an opaque 3-band sRGB image of exactly width x height.
    def fitted_photo(path, width:, height:, fit:)
      if fit == :contain
        img = Vips::Image.thumbnail(path, width, height: height, size: :down)
        img = img.colourspace(:srgb) unless img.interpretation == :srgb
        img = img.flatten(background: hex_to_rgb(CREAM)) if img.has_alpha?
        left = ((width - img.width) / 2.0).round
        top = ((height - img.height) / 2.0).round
        img.embed(left, top, width, height, extend: :background, background: hex_to_rgb(CREAM))
      else
        img = Vips::Image.thumbnail(path, width, height: height, crop: :centre)
        img = img.colourspace(:srgb) unless img.interpretation == :srgb
        img = img.flatten(background: hex_to_rgb(CREAM)) if img.has_alpha?
        img
      end
    end

    def title_text(value, size: 76, line_height: 1.04)
      text(value, size: size, face: 'Trocchi', colour: BROWN,
                  wrap_width: TITLE_MAX_WIDTH, max_height: TITLE_MAX_HEIGHT, line_height: line_height)
    end

    # Render text via pango. Returns an RGBA image in the given colour.
    # - wrap_width enables wrapping; with max_height vips shrinks the font to fit.
    # - max_width (no wrapping) truncates with an ellipsis instead.
    # rubocop:disable Metrics/ParameterLists -- keyword args mirroring CSS text properties
    def text(value, size:, face:, colour:, weight: nil, letter_spacing: nil,
             wrap_width: nil, max_height: nil, line_height: nil, max_width: nil, align: :low)
      value = value.to_s.strip
      mask = text_mask(value, size:, face:, weight:, letter_spacing:, line_height:, wrap_width:, align:)

      if max_height && mask.height > max_height
        mask = text_mask(value, size:, face:, weight:, letter_spacing:, line_height:, wrap_width:,
                                max_height:, align:, autofit: true)
      end

      if max_width && mask.width > max_width
        value = value.dup
        while value.length > 1 && mask.width > max_width
          value = value[0..-2].rstrip
          mask = text_mask("#{value}…", size:, face:, weight:, letter_spacing:, line_height:,
                                        wrap_width:, align:)
        end
      end

      mask.new_from_image(hex_to_rgb(colour)).copy(interpretation: :srgb).bandjoin(mask)
    end

    def text_mask(value, size:, face:, weight:, letter_spacing:, line_height:, wrap_width:, align:,
                  max_height: nil, autofit: false)
      attrs = %(face="#{face}")
      attrs << %( weight="#{weight}") if weight
      attrs << %( letter_spacing="#{(letter_spacing * 1024).round}") if letter_spacing
      attrs << %( line_height="#{line_height}") if line_height
      markup = "<span #{attrs}>#{ERB::Util.html_escape(value)}</span>"

      # Point sizes at 72dpi render 1pt == 1px. With autofit the dpi is left
      # for vips to choose: it picks the largest that fits width x height,
      # shrinking overlong titles to fit.
      options = { font: size.to_s, align: align }
      options[:width] = wrap_width if wrap_width
      if autofit
        options[:height] = max_height
      else
        options[:dpi] = 72
      end
      Vips::Image.text(markup, **options)
    end
    # rubocop:enable Metrics/ParameterLists

    def icon_image(name, size: ROW_ICON_SIZE, colour: ICON_BROWN)
      svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" width="#{size}" height="#{size}" viewBox="0 0 24 24"
             fill="none" stroke="#{colour}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          #{ICON_PATHS.fetch(name)}
        </svg>
      SVG
    end

    def svg(markup, scale: 1.0, opacity: nil)
      img = Vips::Image.new_from_buffer(markup, '', scale: scale)
      img = apply_opacity(img, opacity) if opacity
      img
    end

    def svg_asset(filename, height: nil, width: nil, opacity: nil)
      buffer = File.read(ASSETS_DIR.join(filename))
      probe = Vips::Image.new_from_buffer(buffer, '')
      scale = if height
                height.to_f / probe.height
              elsif width
                width.to_f / probe.width
              else
                1.0
              end
      img = Vips::Image.new_from_buffer(buffer, '', scale: scale)
      img = apply_opacity(img, opacity) if opacity
      img
    end

    def apply_opacity(img, opacity)
      img * [1.0, 1.0, 1.0, opacity]
    end

    def composite(base, overlay, left, top)
      base.composite2(overlay, :over, x: left.round, y: top.round)
    end

    def hex_to_rgb(hex)
      hex.delete('#').scan(/../).map { |c| c.to_i(16) }
    end

    def t(key, **)
      I18n.t(key, scope: 'og_image', **)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
