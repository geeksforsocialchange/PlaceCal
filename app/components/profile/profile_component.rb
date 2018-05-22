# frozen_string_literal: true

class ProfileComponent < MountainView::Presenter
  properties :user

  def name
    user.full_name
  end

  def phone
    user.phone
  end

  def email
    user.email
  end
end
