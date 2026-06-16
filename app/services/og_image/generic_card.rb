# frozen_string_literal: true

module OgImage
  # Default fallback: full brand statement on brown, with the cream
  # leaf-dot pattern in opposite corners.
  class GenericCard < BaseCard
    def to_png
      render.write_to_buffer('.png')
    end

    private

    def render
      canvas = brown_background
      canvas = compose_patterns(canvas)
      compose_brand(canvas)
    end

    def brown_background
      Vips::Image.black(WIDTH, HEIGHT, bands: 3).new_from_image(hex_to_rgb(BROWN))
                 .copy(interpretation: :srgb).bandjoin(255)
    end

    def compose_patterns(canvas)
      pattern = svg_asset('pattern.svg', width: 300, opacity: 0.22)
      canvas = composite(canvas, pattern, -40, -40)
      composite(canvas, pattern.rot180, WIDTH - pattern.width + 40, HEIGHT - pattern.height + 40)
    end

    def compose_brand(canvas)
      logo = svg_asset('logo-cream.svg', width: 560)
      statement = text(t('generic.statement'), size: 44, face: 'Trocchi', colour: CREAM,
                                               wrap_width: 760, line_height: 1.25, align: :centre)

      total_height = logo.height + 42 + statement.height
      top = (HEIGHT - total_height) / 2
      canvas = composite(canvas, logo, (WIDTH - logo.width) / 2, top)
      composite(canvas, statement, (WIDTH - statement.width) / 2, top + logo.height + 42)
    end
  end
end
