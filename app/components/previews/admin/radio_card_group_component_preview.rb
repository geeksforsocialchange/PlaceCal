# frozen_string_literal: true

# @label Radio Card Group
# @note Requires a form context - showing static HTML approximation
class Admin::RadioCardGroupComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/radio_card_group_component_preview/default')
  end

  # @label With Descriptions
  def with_descriptions
    render_with_template(template: 'admin/radio_card_group_component_preview/with_descriptions')
  end
end
