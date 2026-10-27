# frozen_string_literal: true

# @display context directory
class UIFieldPreview < Lookbook::Preview
  # @label Text input
  def text_input
    render(Frame.new { |f| f.render(Components::UI::Field.new(label: "Search", id: "q")) { f.render Components::UI::Input.new(id: "q", placeholder: "Partner name or keyword") } })
  end

  # @label With hint
  # @notes The hint is linked to the input with aria-describedby.
  def with_hint
    render(Frame.new do |f|
      f.render(Components::UI::Field.new(label: "New password", id: "pw", hint: "(8 characters minimum)")) do |field|
        f.render Components::UI::Input.new(type: "password", reveal: true, id: "pw", aria: { describedby: field.hint_id })
      end
    end)
  end

  # @label Select
  def select
    render(Frame.new { |f| f.render Components::UI::Select.new(name: "category", label_text: "Category", options: [{ id: "arts", name: "Arts" }]) })
  end

  class Frame < Phlex::HTML
    def view_template(&)
      div(style: "min-height: 100vh; padding: 2rem; background: var(--color-background); max-width: 30rem") { yield(self) }
    end
  end
end
