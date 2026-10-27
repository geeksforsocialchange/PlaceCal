# frozen_string_literal: true

# @display context directory
class UIInputPreview < Lookbook::Preview
  # @label Text
  def text
    render(Frame.new { |f| f.render Components::UI::Input.new(placeholder: "Search partners") })
  end

  # @label Filled
  def filled
    render(Frame.new { |f| f.render Components::UI::Input.new(type: "email", value: "someone@example.org") })
  end

  # @label Password
  # @notes `reveal: true` adds the eye button that shows and hides the password.
  def password
    render(Frame.new { |f| f.render Components::UI::Input.new(type: "password", reveal: true, id: "password", value: "hunter22") })
  end

  # @label Filter row
  # @notes Input, select and field-shaped buttons share one height, as in the partner and event filters.
  def filter_row
    render(Frame.new do |f|
      f.div(style: "display: flex; gap: 0.5rem; align-items: end") do
        f.div(style: "flex: 1") { f.render Components::UI::Input.new(placeholder: "Search events") }
        f.render Components::UI::Select.new(name: "period", options: [{ id: "week", name: "This week" }], selected: "week", include_blank: false)
        f.render Components::UI::Button.new(variant: :dark, size: :sm, shape: :field, type: "submit") { "Filter" }
      end
    end)
  end

  class Frame < Phlex::HTML
    def view_template(&content)
      div(style: "max-width: 40rem") { yield(self) }
    end
  end
end
