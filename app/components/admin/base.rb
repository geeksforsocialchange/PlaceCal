# frozen_string_literal: true

class Components::Admin::Base < Components::Base
  include Components::Admin::SvgIcons

  register_output_helper :level_badge
  register_value_helper :options_for_importer
  register_value_helper :image_uploader_hint

  private

  def nested_form_remove_link(form, css_class, &)
    raw form.hidden_field(:_destroy, value: false)
    a(href: '#', class: css_class, aria_label: t('admin.actions.remove'), data_action: 'nested-form#remove', &)
  end
end
