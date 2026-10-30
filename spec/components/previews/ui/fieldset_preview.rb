# frozen_string_literal: true

# @display context directory
# @display width form
class UI::FieldsetPreview < Lookbook::Preview
  # @label Choices
  # @notes The legend names the group for screen readers; it matches UI::Field's strong label.
  def choices
    render(Frame.new do |f|
      f.render(Components::UI::Fieldset.new(legend: "I'd like")) do
        f.render(Components::UI::Choice.new(label: "A ring back")) { f.input(type: "checkbox", name: "ringback") }
      end
    end)
  end

  class Frame < Phlex::HTML
    def view_template(&)
      div { yield(self) }
    end
  end
end
