# frozen_string_literal: true

# @label Address Fields
# @note Requires form builder and Partner model - showing static HTML approximation
class Admin::AddressFieldsComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/address_fields_component_preview/default')
  end
end
