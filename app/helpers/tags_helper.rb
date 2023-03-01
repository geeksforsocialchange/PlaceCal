# frozen_string_literal: true

# app/helpers/tags_helper.rb
module TagsHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:id, :name)
  end

  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end

  def show_assigned_user_field_for(form)
    [Tag, Partnership].include?(form.object.class)
  end
end
