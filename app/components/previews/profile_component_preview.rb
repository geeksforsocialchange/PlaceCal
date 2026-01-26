# frozen_string_literal: true

class ProfileComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    user = OpenStruct.new(
      full_name: 'Jane Smith',
      email: 'jane.smith@example.com',
      phone: '0161 123 4567'
    )
    render(ProfileComponent.new(user: user))
  end

  # @label Without Phone
  def without_phone
    user = OpenStruct.new(
      full_name: 'John Doe',
      email: 'john.doe@example.com',
      phone: nil
    )
    render(ProfileComponent.new(user: user))
  end
end
