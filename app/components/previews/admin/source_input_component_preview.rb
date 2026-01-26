# frozen_string_literal: true

# @label Source Input
# @note Requires form builder - showing static HTML approximation
class Admin::SourceInputComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/source_input_component_preview/default')
  end

  # @label Without Importer
  def without_importer
    render_with_template(template: 'admin/source_input_component_preview/without_importer')
  end
end
