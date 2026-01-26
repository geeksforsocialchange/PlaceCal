# frozen_string_literal: true

# @label Toggle Card
# @note Requires a form context - showing static HTML approximation
class Admin::ToggleCardComponentPreview < ViewComponent::Preview
  # @label Success Variant (Default)
  def success
    render_with_template(template: 'admin/toggle_card_component_preview/success')
  end

  # @label Warning Variant
  def warning
    render_with_template(template: 'admin/toggle_card_component_preview/warning')
  end

  # @label Error Variant
  def error
    render_with_template(template: 'admin/toggle_card_component_preview/error')
  end
end
