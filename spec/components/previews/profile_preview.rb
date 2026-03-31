# frozen_string_literal: true

class ProfilePreview < Lookbook::Preview
  # @label With all details
  def with_all_details
    render Components::Profile.new(user: PreviewSupport.sample_user)
  end

  # @label Without phone
  def without_phone
    render Components::Profile.new(user: PreviewSupport.sample_user_minimal)
  end
end
