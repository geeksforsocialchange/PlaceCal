# frozen_string_literal: true

# @label Tab Panel
class Admin::TabPanelComponentPreview < ViewComponent::Preview
  # @label Default (Unchecked)
  def default
    render(Admin::TabPanelComponent.new(
             name: 'partner_tabs',
             label: 'Basic Info',
             hash: 'basic',
             controller_name: 'partners'
           )) do
      '<div class="p-4">
        <p>This is the content for the Basic Info tab.</p>
      </div>'.html_safe
    end
  end

  # @label Checked (Active)
  def checked
    render(Admin::TabPanelComponent.new(
             name: 'partner_tabs',
             label: 'Location',
             hash: 'location',
             controller_name: 'partners',
             checked: true
           )) do
      '<div class="p-4">
        <p>This is the active Location tab content.</p>
      </div>'.html_safe
    end
  end

  # @label Multiple Tabs Example
  def multiple_tabs
    render_with_template(template: 'admin/tab_panel_component_preview/multiple_tabs')
  end
end
