# frozen_string_literal: true

class Views::Admin::Base < Views::Base
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
end
