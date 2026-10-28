# frozen_string_literal: true

# @display context directory
# @display width form
class UI::InputPreview < Lookbook::Preview
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
  # @display width page
  # @notes Input, select and field-shaped buttons share one height, as in the partner and event filters.
  def filter_row
    render(Frame.new do |f|
      f.div(class: "flex gap-2 items-end") do
        f.div(class: "flex-1") { f.render Components::UI::Input.new(placeholder: "Search events") }
        f.render Components::UI::Select.new(name: "period", options: [{ id: "week", name: "This week" }], selected: "week", include_blank: false)
        f.render Components::UI::Button.new(variant: :dark, size: :sm, shape: :field, type: "submit") { "Filter" }
      end
    end)
  end

  class Frame < Phlex::HTML
    def view_template(&content)
      div { yield(self) }
    end
  end
end
