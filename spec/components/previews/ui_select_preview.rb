# frozen_string_literal: true

# @display context directory
class UISelectPreview < Lookbook::Preview
  OPTIONS = [{ id: "arts", name: "Arts", count: 12 }, { id: "health", name: "Health", count: 4 }].freeze

  # @label With label
  def with_label
    render Components::UI::Select.new(name: "category", label_text: "Category", options: OPTIONS)
  end

  # @label Selected
  def selected
    render Components::UI::Select.new(name: "category", label_text: "Category", options: OPTIONS, selected: "health")
  end

  # @label Grouped options
  def grouped
    render Components::UI::Select.new(
      name: "ward", label_text: "Ward",
      options: [{ group: "Manchester", items: [{ id: 1, name: "Hulme" }, { id: 2, name: "Moss Side" }] }]
    )
  end
end
