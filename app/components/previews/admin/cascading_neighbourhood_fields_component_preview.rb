# frozen_string_literal: true

# @label Cascading Neighbourhood Fields
# @note Requires form builder - showing static HTML approximation
class Admin::CascadingNeighbourhoodFieldsComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/cascading_neighbourhood_fields_component_preview/default')
  end

  # @label Without Remove Button
  def without_remove
    render_with_template(template: 'admin/cascading_neighbourhood_fields_component_preview/without_remove')
  end
end
