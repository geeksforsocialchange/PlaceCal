# frozen_string_literal: true

# @label Image Upload
# @note Requires form builder - showing static HTML approximation
class Admin::ImageUploadComponentPreview < ViewComponent::Preview
  # @label Empty State
  def empty
    render_with_template(template: 'admin/image_upload_component_preview/empty')
  end

  # @label With Image
  def with_image
    render_with_template(template: 'admin/image_upload_component_preview/with_image')
  end

  # @label Avatar Style
  def avatar
    render_with_template(template: 'admin/image_upload_component_preview/avatar')
  end
end
