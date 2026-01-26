# frozen_string_literal: true

# @label Tab Form
# @note Requires form builder and record - showing static HTML approximation
class Admin::TabFormComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/tab_form_component_preview/default')
  end
end
