# frozen_string_literal: true

class Views::Admin::Components::TabForm < Views::Admin::Components::Base
  def initialize(tabs:, tab_name:, storage_key:, form:, record:, settings_hash: nil, preview_hash: nil) # rubocop:disable Metrics/ParameterLists
    @tabs = tabs
    @tab_name = tab_name
    @storage_key = storage_key
    @settings_hash = settings_hash
    @preview_hash = preview_hash
    @form = form
    @record = record
  end

  def view_template
    div(class: 'tabs tabs-lift') do
      visible_tabs.each_with_index do |tab, index|
        div(class: 'tab flex-1 cursor-default') if tab[:spacer_before]

        render Views::Admin::Components::TabPanel.new(
          name: @tab_name,
          label: tab[:label],
          hash: tab[:hash],
          controller_name: 'form-tabs',
          checked: index.zero?
        ) do
          raw helpers.render(tab[:partial], f: @form)
        end
      end
    end

    render Views::Admin::Components::SaveBar.new(
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
