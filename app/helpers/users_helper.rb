# frozen_string_literal: true

# app/helpers/users_helper.rb
module UsersHelper
  def gravatar_for(user, size: 240)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url,
              alt: "A photo of #{user.full_name}",
              class: 'gravatar')
  end
end
