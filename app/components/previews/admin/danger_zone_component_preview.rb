# frozen_string_literal: true

# @label Danger Zone
class Admin::DangerZoneComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::DangerZoneComponent.new(
             title: 'Delete Partner',
             description: 'Once you delete this partner, there is no going back. Please be certain.',
             button_text: 'Delete Partner',
             button_path: '/admin/partners/1'
           ))
  end

  # @label With Confirmation
  def with_confirmation
    render(Admin::DangerZoneComponent.new(
             title: 'Delete Calendar',
             description: 'This will permanently delete the calendar and all associated events.',
             button_text: 'Delete Calendar',
             button_path: '/admin/calendars/1',
             confirm: 'Are you sure you want to delete this calendar? This cannot be undone.'
           ))
  end
end
