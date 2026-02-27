# frozen_string_literal: true

class Components::Admin::Base < Components::Base
  include Components::Admin::SvgIcons

  register_output_helper :nested_form_remove_link
  register_output_helper :level_badge
  register_value_helper :options_for_importer
  register_value_helper :image_uploader_hint
end
