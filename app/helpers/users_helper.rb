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

  def options_for_roles
    User.role.values
  end

  def user_has_no_rights?(user)
    return false if user.tag_admin?
    return false if user.neighbourhood_admin?
    return false if user.partner_admin?

    true # they have no rights
  end

  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:name, :id)
  end

  def options_for_neighbourhoods
    policy_scope(Neighbourhood)
      .where('name is not null and name != \'\'')
      .order(:name)
      .all
      .collect { |ward| [ward.contextual_name, ward.id] }
  end

  def options_for_tags
    policy_scope(Tag).order(:name).pluck(:name, :id)
  end

  def role_label(value)
    case value.second
    when 'root'
      '<strong>Root</strong>: Can do everything'.html_safe
    when 'editor'
      '<strong>Editor</strong>: Can edit news articles'.html_safe
    when 'citizen'
      '<strong>Citizen</strong>: ' \
      'Can only edit entities listed on this page'.html_safe
    else
      value
    end
  end
end
