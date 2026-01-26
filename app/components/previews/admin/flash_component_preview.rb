# frozen_string_literal: true

# @label Flash Messages
class Admin::FlashComponentPreview < ViewComponent::Preview
  # @label Notice
  def notice
    render(Admin::FlashComponent.new(flash: { notice: 'Your changes have been saved.' }))
  end

  # @label Success
  def success
    render(Admin::FlashComponent.new(flash: { success: 'Partner created successfully!' }))
  end

  # @label Alert
  def alert
    render(Admin::FlashComponent.new(flash: { alert: 'Please review the form errors.' }))
  end

  # @label Error
  def error
    render(Admin::FlashComponent.new(flash: { error: 'Unable to save. Please try again.' }))
  end

  # @label Multiple Messages
  def multiple
    render(Admin::FlashComponent.new(flash: {
                                       notice: 'Calendar imported.',
                                       alert: 'Some events could not be processed.'
                                     }))
  end

  # @label Empty
  def empty
    render(Admin::FlashComponent.new(flash: {}))
  end
end
