# frozen_string_literal: true

class Components::Admin::TabForm < Components::Admin::Base
  prop :tabs, Array
  prop :tab_name, String
  prop :storage_key, String
  prop :form, ActionView::Helpers::FormBuilder
  prop :record, _Interface(:model_name) # ActiveRecord model
  prop :settings_hash, _Nilable(String), default: nil
  prop :preview_hash, _Nilable(String), default: nil

  def view_template
    div(class: 'tabs tabs-lift') do
      visible_tabs.each_with_index do |tab, index|
        div(class: 'tab flex-1 cursor-default') if tab[:spacer_before]

        render Components::Admin::TabPanel.new(
          name: @tab_name,
          label: tab[:label],
          hash: tab[:hash],
          controller_name: 'form-tabs',
          checked: index.zero?
        ) do
          raw(view_context.render(tab[:partial], f: @form))
        end
      end
    end

    render Components::Admin::SaveBar.new(
      multi_step: true,
      tab_name: @tab_name,
      settings_hash: @settings_hash,
      preview_hash: @preview_hash,
      storage_key: @storage_key
    )
  end

  private

  def visible_tabs
    @tabs.select { |tab| !tab[:persisted_only] || @record.persisted? }
  end
end
