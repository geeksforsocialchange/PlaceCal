# frozen_string_literal: true

# @label Alert
class Admin::AlertComponentPreview < ViewComponent::Preview
  # @label Notice (Info)
  def notice
    render(Admin::AlertComponent.new(type: :notice, message: 'This is an informational message.'))
  end

  # @label Success
  def success
    render(Admin::AlertComponent.new(type: :success, message: 'Operation completed successfully!'))
  end

  # @label Warning
  def warning
    render(Admin::AlertComponent.new(type: :alert, message: 'Please review before proceeding.'))
  end

  # @label Error
  def error
    render(Admin::AlertComponent.new(type: :error, message: 'Something went wrong. Please try again.'))
  end

  # @label Danger
  def danger
    render(Admin::AlertComponent.new(type: :danger, message: 'This action cannot be undone!'))
  end
end
