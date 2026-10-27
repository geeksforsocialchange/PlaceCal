# frozen_string_literal: true

# @display context directory
class UI::ButtonPreview < Lookbook::Preview
  # @label Links
  # @notes Every variant at every size, rendered as `<a>` (an `href` is given).
  def links
    render Grid.new(href: "#")
  end

  # @label Buttons
  # @notes The same grid as `<button>` elements (no `href`).
  def buttons
    render Grid.new(href: nil)
  end

  # @label Field shape
  # @notes `shape: :field` squares the corners and matches the 42px filter controls, as in the partner filter.
  def field
    render FieldRow.new
  end

  # @label Playground
  # @param variant select { choices: [primary, dark, outline, dark_outline, light, join] }
  # @param size select { choices: [sm, md, lg] }
  # @param shape select { choices: [pill, field] }
  # @param link toggle
  # @param label text
  def playground(variant: "dark", size: "md", shape: "pill", link: true, label: "Find out more")
    render Single.new(variant: variant.to_sym, size: size.to_sym, shape: shape.to_sym, href: (link ? "#" : nil), label:)
  end

  PAGE_STYLE = "color: var(--color-foreground)"
  # :light is a cream button, so it is shown on the salmon panel it is made for.
  PANEL_STYLE = { light: "background: var(--color-secondary)" }.freeze

  class Grid < Phlex::HTML
    def initialize(href:)
      super()
      @href = href
    end

    def view_template
      div(style: "#{PAGE_STYLE}; display: grid; gap: 1rem; align-content: start") do
        Components::UI::Button::VARIANTS.each_key do |variant|
          div(style: "display: grid; grid-template-columns: 8rem 1fr; align-items: center; gap: 1rem") do
            code { ":#{variant}" }
            div(style: "display: flex; flex-wrap: wrap; align-items: center; gap: 0.75rem; padding: 0.75rem; " \
                       "border-radius: 0.5rem; #{PANEL_STYLE[variant]}") do
              Components::UI::Button::SIZES.each_key do |size|
                render Components::UI::Button.new(variant:, size:, href: @href) { "#{size.to_s.upcase} button" }
              end
            end
          end
        end
      end
    end
  end

  class FieldRow < Phlex::HTML
    def view_template
      div(style: PAGE_STYLE) do
        div(style: "display: flex; gap: 0.5rem; align-items: end; padding: 1rem; " \
                   "border-radius: 1rem; background: var(--color-home-background-3); font-size: var(--text-sm)") do
          input(type: "text", placeholder: "Search partners",
                style: "height: var(--height-field); padding: 0 1rem; border: 2px solid var(--color-rules); " \
                       "border-radius: var(--radius-sm); background: var(--color-background)")
          render Components::UI::Button.new(variant: :dark, size: :sm, shape: :field) { "Apply" }
          render Components::UI::Button.new(variant: :dark_outline, size: :sm, shape: :field, href: "#") { "Clear" }
        end
      end
    end
  end

  class Single < Phlex::HTML
    def initialize(label:, **button)
      super()
      @label = label
      @button = button
    end

    def view_template
      div(style: "#{PAGE_STYLE}; #{PANEL_STYLE[@button[:variant]]}") do
        render Components::UI::Button.new(**@button) { @label }
      end
    end
  end
end
