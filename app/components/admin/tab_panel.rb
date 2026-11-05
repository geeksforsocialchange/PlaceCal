# frozen_string_literal: true

class Components::Admin::TabPanel < Components::Admin::Base
  prop :name, String
  prop :label, String
  prop :hash, String
  prop :controller_name, String
  prop :checked, _Boolean, default: false

  # A leading emoji is decoration: shown through data-icon, kept out of the accessible name.
  LEADING_EMOJI = /\A((?:\p{Extended_Pictographic}[\u{FE0F}\u{200D}]*)+)\s+/

  def view_template(&block)
    input(
      type: 'radio',
      name: @name,
      class: 'tab',
      aria_label: @label.sub(LEADING_EMOJI, ''),
      data_icon: @label[LEADING_EMOJI, 1],
      **{ "data-#{@controller_name}-target" => 'tab' },
      data_hash: @hash,
      **(@checked ? { checked: 'checked' } : {})
    )
    div(
      class: 'tab-content bg-base-100 border-base-300 p-6',
      **{ "data-#{@controller_name}-target" => 'panel' },
      data_section: @hash
    ) do
      yield if block
    end
  end
end
