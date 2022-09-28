# frozen_string_literal: true

# app/helpers/tags_helper.rb
module TagsHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:id, :name)
  end

  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end

  def edit_permission_label(value)
    case value.second
    when "root"
      "<strong>Root</strong>: Non-Root users must explicitly be granted " \
        "permission to assign this tag".html_safe
    when "all"
      "<strong>All</strong>: Any user may assign this tag".html_safe
    else
      value
    end
  end
end
