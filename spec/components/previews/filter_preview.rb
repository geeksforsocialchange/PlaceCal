# frozen_string_literal: true

class FilterPreview < Lookbook::Preview
  # @label Default (no selection)
  def default
    render Components::Filter.new(
      name: "category",
      label: "Category",
      items: [
        { id: 1, name: "Social", count: 12 },
        { id: 2, name: "Health & Wellbeing", count: 8 },
        { id: 3, name: "Arts & Culture", count: 5 }
      ],
      selected_id: 0,
      controller: "partner-filter-component",
      toggle_action: "toggleCategory",
      submit_action: "submitCategory",
      reset_action: "resetCategory"
    )
  end

  # @label With selection
  def with_selection
    render Components::Filter.new(
      name: "category",
      label: "Category",
      items: [
        { id: 1, name: "Social", count: 12 },
        { id: 2, name: "Health & Wellbeing", count: 8 },
        { id: 3, name: "Arts & Culture", count: 5 }
      ],
      selected_id: 2,
      controller: "partner-filter-component",
      toggle_action: "toggleCategory",
      submit_action: "submitCategory",
      reset_action: "resetCategory"
    )
  end
end
