# frozen_string_literal: true

# @display context directory
# @display width form
class UI::FieldPreview < Lookbook::Preview
  # @label Text input
  def text_input
    render(Frame.new { |f| f.render(Components::UI::Field.new(label: "Search", id: "q")) { f.render Components::UI::Input.new(id: "q", placeholder: "Partner name or keyword") } })
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

  # @label Strong
  # @notes A bold label marked required or optional, with the roomy input, as on the contact form.
  def strong
    render(Frame.new do |f|
      f.render(Components::UI::Field.new(label: "Name", id: "name", variant: :strong, required: true)) { f.render Components::UI::Input.new(id: "name", variant: :roomy) }
      f.render(Components::UI::Field.new(label: "Why", id: "why", variant: :strong, required: false)) { f.render Components::UI::Input.new(id: "why", variant: :roomy, rows: 4) }
    end)
  end

  # @label Select
  def select
    render(Frame.new { |f| f.render Components::UI::Select.new(name: "category", label_text: "Category", options: [{ id: "arts", name: "Arts" }]) })
  end

  # @label Group
  # @notes `group: true` labels several controls at once, such as the directory's neighbourhood dropdowns: the wrapper is the group, named by the label.
  def group
    render(Frame.new do |f|
      f.render(Components::UI::Field.new(label: "Neighbourhood", id: "neighbourhood_cascade", group: true)) do
        f.render Components::UI::Select.new(name: "region", options: [{ id: "north", name: "Northvale" }])
        f.render Components::UI::Select.new(name: "district", options: [{ id: "millbrook", name: "Millbrook" }])
      end
    end)
  end

  class Frame < Phlex::HTML
    def view_template(&)
      div { yield(self) }
    end
  end
end
