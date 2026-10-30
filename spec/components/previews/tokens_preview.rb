# frozen_string_literal: true

# Renders the public design tokens straight from _theme.css, so the sheet
# always matches what the build ships.
class TokensPreview < Lookbook::Preview
  THEME_CSS = Rails.root.join("app/tailwind/public/_theme.css")
  # Matches --root-font-size in app/tailwind/public/_theme.css
  ROOT_PX = 18
  SAMPLE = "Community coffee morning at the library"
  PARAGRAPH = "A friendly weekly coffee morning for everyone in the neighbourhood. " \
              "Bring a friend, meet new people and find out what else is happening nearby."

  # @label Type scale
  # @notes Sorted by rendered size. Sans and serif samples per token. Values are the defaults in _theme.css; samples use the theme picked in the Theme menu.
  def type_scale
    render Sheet.new(:type, root_tokens("text"))
  end

  # @label Fonts, weights and tracking
  # @notes Values are the defaults in _theme.css; samples use the theme picked in the Theme menu.
  def fonts
    render Sheet.new(:font, root_tokens("font").merge(root_tokens("tracking")))
  end

  # @label Line heights
  # @notes `normal` is the browser default the cards used before these tokens existed.
  def line_heights
    render Sheet.new(:leading, { "normal" => "normal" }.merge(root_tokens("leading")))
  end

  # @label Colours
  # @notes Values are the defaults in _theme.css. Swatches show the theme picked in the Theme menu, which may override them (the built-in colour themes are in _themes.css).
  def colours
    render Sheet.new(:colour, root_tokens("color"))
  end

  # @label Radii and shadows
  def radii_and_shadows
    render Sheet.new(:radius, root_tokens("radius").merge(root_tokens("shadow")))
  end

  # @label Breakpoints and widths
  def breakpoints
    render Sheet.new(:measure, all_tokens("breakpoint").merge(root_tokens("width")))
  end

  private

  def root_tokens(prefix)
    block = THEME_CSS.read[/^:root \{(.*?)^\}/m, 1]
    block.scan(/(--#{prefix}-[\w-]+):\s*([^;]+);/).to_h
  end

  def all_tokens(prefix)
    THEME_CSS.read.scan(/(--#{prefix}-[\w-]+):\s*([^;]+);/).to_h
  end

  class Sheet < Phlex::HTML
    def initialize(kind, tokens)
      super()
      @kind = kind
      @tokens = tokens
    end

    def view_template
      div(class: "grid content-start gap-6 text-foreground") do
        rows.each { |name, value| row(name, value) }
      end
    end

    private

    def rows
      return @tokens unless @kind == :type

      @tokens.sort_by { |_, value| rem(value) || Float::INFINITY }
    end

    def rem(value)
      value[/\A([\d.]+)rem\z/, 1]&.to_f
    end

    def row(name, value)
      div(class: "flex items-start gap-6") do
        div(class: "w-64 shrink-0") do
          code(class: "font-bold") { name }
          div(class: "mt-1 text-sm opacity-70") { label(value) }
        end
        sample(name, value)
      end
    end

    def label(value)
      size = rem(value)
      size ? "#{value} (#{(size * ROOT_PX).round(1)}px)" : value
    end

    def sample(name, value)
      case @kind
      when :type
        div do
          div(style: "font-size: var(#{name}); line-height: 1.2") { SAMPLE }
          div(class: "mt-1 font-serif", style: "font-size: var(#{name}); line-height: 1.2") { SAMPLE }
        end
      when :font then div(style: font_style(name)) { SAMPLE }
      when :leading
        p(class: "m-0 max-w-(--width-prose)", style: "line-height: #{name == 'normal' ? 'normal' : "var(#{name})"}") { "#{PARAGRAPH} #{PARAGRAPH}" }
      when :colour
        div(class: "h-12 rounded-sm border border-foreground/15", style: "background: var(#{name})")
      when :radius
        shadow = name.start_with?("--shadow-")
        div(class: ["w-32 h-16 bg-surface", ("border-2 border-current" unless shadow)].compact.join(" "),
            style: shadow ? "box-shadow: var(#{name})" : "border-radius: var(#{name})")
      when :measure
        div(class: "h-3 rounded-pill bg-primary", style: "width: min(#{value}, 100%)")
      end
    end

    def font_style(name)
      return "letter-spacing: var(#{name}); text-transform: uppercase" if name.start_with?("--tracking-")
      return "font-weight: var(#{name}); font-size: var(--text-lg)" if name.start_with?("--font-weight-")

      "font-family: var(#{name}); font-size: var(--text-lg)"
    end
  end
end
