# frozen_string_literal: true

class Views::Admin::Base < Views::Base
  include Components::Admin
  include Components::Admin::SvgIcons
  include Phlex::Rails::Helpers::CheckBoxTag

  register_output_helper :simple_form_for
  register_output_helper :filtered_form_for
  register_output_helper :nested_form_for
  register_output_helper :nested_form_remove_link
  register_output_helper :level_badge
  register_value_helper :options_for_importer
  register_value_helper :image_uploader_hint
  register_value_helper :options_for_organiser
  register_value_helper :options_for_location
  register_value_helper :options_for_partners
  register_value_helper :options_for_users
  register_value_helper :options_for_user_partnerships
  register_value_helper :permitted_options_for_partners
  register_value_helper :attr_label
  register_value_helper :show_assigned_user_field_for?
  register_value_helper :options_for_events
  register_value_helper :calendar_import_sources
  register_value_helper :options_for_partner_users
  register_value_helper :options_for_partner_partnerships
  register_value_helper :permitted_options_for_partner_tags
  register_value_helper :partner_has_unmappable_postcode?
  register_value_helper :options_for_tags
  register_value_helper :user_has_no_rights?
end
