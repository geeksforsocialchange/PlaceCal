# frozen_string_literal: true

# @label Error (Form Errors)
class Admin::ErrorComponentPreview < ViewComponent::Preview
  # @label With Errors
  def with_errors
    # Create a mock object with errors
    mock_object = ErrorMockObject.new
    mock_object.errors.add(:name, "can't be blank")
    mock_object.errors.add(:email, 'is invalid')
    mock_object.errors.add(:email, 'has already been taken')

    render(Admin::ErrorComponent.new(mock_object))
  end

  # @label No Errors
  def no_errors
    mock_object = ErrorMockObject.new
    render(Admin::ErrorComponent.new(mock_object))
  end

  # Mock object for preview purposes
  class ErrorMockObject
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :name, :email

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Partner')
    end
  end
end
