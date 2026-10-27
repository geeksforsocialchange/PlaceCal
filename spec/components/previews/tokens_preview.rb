# frozen_string_literal: true

# Renders the public design tokens straight from _theme.css, so the sheet
# always matches what the build ships.
class TokensPreview < Lookbook::Preview
  THEME_CSS = Rails.root.join("app/tailwind/public/_theme.css")
  SAMPLE = "Community coffee morning at the library"
  PARAGRAPH = "A friendly weekly coffee morning for everyone in the neighbourhood. " \
              "Bring a friend, meet new people and find out what else is happening nearby."

  # @label Type scale
  # @notes Sorted by rendered size. Sans and serif samples per token.
  def type_scale
    render Sheet.new(:type, root_tokens("text"))
  end

  # @label Line heights
  # @notes `normal` is the browser default the cards used before these tokens existed.
  def line_heights
    render Sheet.new(:leading, { "normal" => "normal" }.merge(root_tokens("leading")))
  end

  # @label Colours
  def colours
    render Sheet.new(:colour, root_tokens("color"))
  end

  # @label Radii and shadows
  def radii_and_shadows
    render Sheet.new(:radius, root_tokens("radius").merge(root_tokens("shadow").transform_keys { "shadow-#{it}" }))
  end

  # @label Breakpoints and widths
  def breakpoints
    render Sheet.new(:measure, all_tokens("breakpoint").transform_keys { "breakpoint-#{it}" }
                                 .merge(root_tokens("width").transform_keys { "width-#{it}" }))
  end

  private

  def root_tokens(prefix)
    block = THEME_CSS.read[/^:root \{(.*?)^\}/m, 1]
    block.scan(/--#{prefix}-([\w-]+):\s*([^;]+);/).to_h
  end

  def all_tokens(prefix)
    THEME_CSS.read.scan(/--#{prefix}-([\w-]+):\s*([^;]+);/).to_h
  end

  class Sheet < Phlex::HTML
    def initialize(kind, tokens)
      super()
      @kind = kind
      @tokens = tokens
    end

    def view_template
      div(style: "display: grid; align-content: start; gap: 1.5rem; color: var(--color-foreground)") do
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
      div(style: "display: grid; grid-template-columns: 14rem 1fr; gap: 1.5rem; align-items: start") do
        div do
          code(style: "font-weight: 700") { name }
          div(style: "font-size: 0.8rem; opacity: 0.7; margin-top: 0.25rem") { label(value) }
        end
        sample(name, value)
      end
    end

    def label(value)
      size = rem(value)
      size ? "#{value} (#{(size * 16).round(1)}px)" : value
    end

    def sample(name, value)
      case @kind
      when :type
        div do
          div(style: "font-size: var(--text-#{name}); line-height: 1.2") { SAMPLE }
          div(style: "font-size: var(--text-#{name}); line-height: 1.2; font-family: var(--font-serif); margin-top: 0.25rem") { SAMPLE }
        end
      when :leading
        p(style: "max-width: 36rem; margin: 0; line-height: #{name == 'normal' ? 'normal' : "var(--leading-#{name})"}") do
          "#{PARAGRAPH} #{PARAGRAPH}"
        end
      when :colour
        div(style: "height: 3rem; border-radius: 0.5rem; border: 1px solid rgb(0 0 0 / 0.15); background: var(--color-#{name})")
      when :radius
        css = name.start_with?("shadow-") ? "box-shadow: var(--#{name})" : "border-radius: var(--radius-#{name}); border: 2px solid currentColor"
        div(style: "width: 8rem; height: 4rem; background: var(--color-surface, #fff); #{css}")
      when :measure
        div(style: "width: min(#{value}, 100%); height: 0.75rem; background: var(--color-primary); border-radius: 999px")
      end
    end
  end
end
