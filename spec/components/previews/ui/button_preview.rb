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
  # @param variant select { choices: [primary, dark, outline, dark_outline, light, join, secondary, dark_invert] }
  # @param size select { choices: [sm, md, lg, xl] }
  # @param shape select { choices: [pill, field] }
  # @param link toggle
  # @param label text
  def playground(variant: "dark", size: "md", shape: "pill", link: true, label: "Find out more")
    render Single.new(variant: variant.to_sym, size: size.to_sym, shape: shape.to_sym, href: (link ? "#" : nil), label:)
  end

  # :light is a cream button, so it is shown on the salmon panel it is made for.
  PANEL = { light: "bg-secondary" }.freeze

  class Grid < Phlex::HTML
    def initialize(href:)
      super()
      @href = href
    end

    def view_template
      div(class: "grid content-start gap-4 text-foreground") do
        Components::UI::Button::VARIANTS.each_key do |variant|
          div(class: "flex items-center gap-4") do
            code(class: "w-32 shrink-0") { ":#{variant}" }
            div(class: ["flex flex-wrap items-center gap-3 p-3 rounded-sm", PANEL[variant]].compact.join(" ")) do
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
      div(class: "flex items-end gap-2 p-4 rounded-card bg-home-background-3 text-foreground") do
        div(class: "flex-1") { render Components::UI::Input.new(placeholder: "Search partners") }
        render Components::UI::Button.new(variant: :dark, size: :sm, shape: :field) { "Apply" }
        render Components::UI::Button.new(variant: :dark_outline, size: :sm, shape: :field, href: "#") { "Clear" }
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
      div(class: ["text-foreground", PANEL[@button[:variant]]].compact.join(" ")) do
        render Components::UI::Button.new(**@button) { @label }
      end
    end
  end
end
