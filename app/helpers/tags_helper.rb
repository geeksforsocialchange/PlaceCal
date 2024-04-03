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

  def options_for_tags
    policy_scope(Tag)
      .select(:name, :type, :id)
      .where(type: 'Partnership')
      .order(:name)
      .map { |r| [r.name_with_type, r.id] }
  end

  # prevent invisible partner ids from being overwritten when updating a tag
  def all_partners_for(tag, attributes)
    editable_partners = current_user.partners.pluck(:id)
    uneditable_partners = tag.partner_ids - editable_partners
    updated_partners = editable_partners & attributes[:partner_ids].reject(&:empty?).map(&:to_i)

    uneditable_partners + updated_partners
  end
end
