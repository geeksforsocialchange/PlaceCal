# frozen_string_literal: true

# @display context directory
class UI::FieldPreview < Lookbook::Preview
  # @label Text input
  def text_input
    render(Frame.new do |f|
      f.render(Components::UI::Field.new(label: "Search", id: "q")) do
        f.render Components::UI::Input.new(id: "q", placeholder: "Partner name or keyword")
      end
    end)
  end

  # @label With hint
  # @notes The hint is linked to the input with aria-describedby.
  def with_hint
    render(Frame.new do |f|
      f.render(Components::UI::Field.new(label: "Email", id: "email", hint: "We only use this to send you a login link.")) do |field|
        f.render Components::UI::Input.new(type: "email", id: "email", aria: { describedby: field.hint_id })
      end
    end)
  end

  # @label Select
  def select
    render(Frame.new { |f| f.render Components::UI::Select.new(name: "category", label_text: "Category", options: [{ id: "arts", name: "Arts" }]) })
  end

  class Frame < Phlex::HTML
    def view_template(&)
      div(style: "max-width: 30rem") { yield(self) }
    end
  end
end
