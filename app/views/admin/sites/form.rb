# frozen_string_literal: true

class Views::Admin::Sites::Form < Views::Admin::Base
  prop :site, _Any, reader: :private

  def view_template # rubocop:disable Metrics/MethodLength
    simple_form_for([:admin, site], html: { data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'siteTabAfterSave' } }) do |form|
      render(Components::Admin::Error.new(site))

      render Components::Admin::TabForm.new(
        tabs: [
          { label: "\u{1F4CB} Basic Info", hash: 'basic', partial: 'form_tab_basic' },
          { label: "\u{1F5BC}\u{FE0F} Images", hash: 'images', partial: 'form_tab_images' },
          { label: "\u{1F4CD} Neighbourhoods", hash: 'neighbourhoods', partial: 'form_tab_neighbourhoods' },
          { label: "\u{1F3F7}\u{FE0F} Partnerships", hash: 'partnerships', partial: 'form_tab_partnerships' },
          { label: "\u{1F441}\u{FE0F} Preview", hash: 'preview', partial: 'form_tab_preview', persisted_only: true },
          { label: "\u{2699}\u{FE0F} Settings", hash: 'settings', partial: 'form_tab_settings', spacer_before: true }
        ],
        tab_name: 'site_tabs',
        storage_key: 'siteTabAfterSave',
        settings_hash: 'settings',
        preview_hash: 'preview',
        form: form,
        record: site
      )
    end
  end
end
