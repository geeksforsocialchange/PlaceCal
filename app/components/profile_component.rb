# frozen_string_literal: true

class ProfileComponent < ViewComponent::Base
  def initialize(user:)
    super()
    @user = user
  end

  attr_reader :user

  def name
    user.full_name
  end

  def phone
    return false unless user.phone&.length&.positive?

    user.phone
  end

  delegate :email, to: :user
end
