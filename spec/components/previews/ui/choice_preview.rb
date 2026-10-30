# frozen_string_literal: true

# @display context directory
class UI::ChoicePreview < Lookbook::Preview
  # @label Checkboxes
  # @notes The checkbox is passed in as a block and stays focusable; the chip shows its checked and keyboard focus states.
  def checkboxes
    render(Row.new do |r|
      r.render(Components::UI::Choice.new(label: "A ring back")) { r.input(type: "checkbox", name: "ringback", checked: true) }
      r.render(Components::UI::Choice.new(label: "More information")) { r.input(type: "checkbox", name: "more_info") }
    end)
  end

  class Row < Phlex::HTML
    def view_template(&)
      div(class: "flex flex-wrap gap-2") { yield(self) }
    end
  end
end
