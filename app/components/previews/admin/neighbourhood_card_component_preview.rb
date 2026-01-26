# frozen_string_literal: true

# @label Neighbourhood Card
# @note Requires database records - showing with mock data
class Admin::NeighbourhoodCardComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/neighbourhood_card_component_preview/default')
  end

  # @label Without Header
  def without_header
    render_with_template(template: 'admin/neighbourhood_card_component_preview/without_header')
  end

  # @label With Remove Button
  def with_remove
    render_with_template(template: 'admin/neighbourhood_card_component_preview/with_remove')
  end

  # @label Inline Mode
  def inline
    render_with_template(template: 'admin/neighbourhood_card_component_preview/inline')
  end
end
