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

  def tooltip_label(attribute, title)
    str = attribute 
    str += button_tag('?', class: "btn btn-secondary", data: { toggle: "tooltip", placement: "top"  }, title: title)
    sanitize(str, tags: %w(button), attributes: %w(class type data-toggle data-placement title))
  end

  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:name, :id)
  end

  def options_for_neighbourhoods
    policy_scope(Neighbourhood).
      where('name is not null and name != \'\'').
      order(:name).
      all.
      map { |nh| [nh.contextual_name, nh.id] }
  end

  def options_for_tags
    policy_scope(Tags).order(:name).map { |tag| [tag.name, tag.id] }
  end
end
