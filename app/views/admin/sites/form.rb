# frozen_string_literal: true

class Views::Admin::Sites::Form < Views::Admin::Base
  prop :site, _Any, reader: :private

  def view_template # rubocop:disable Metrics/MethodLength
    simple_form_for([:admin, site], html: { data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'siteTabAfterSave' } }) do |form|
      render(Components::Admin::Error.new(site))

      render Components::Admin::TabForm.new(
        tabs: [
          { label: "\u{1F4CB} Basic Info", hash: 'basic', component: Views::Admin::Sites::FormTabBasic },
          { label: "\u{1F5BC}\u{FE0F} Images", hash: 'images', component: Views::Admin::Sites::FormTabImages },
          { label: "\u{1F4CD} Neighbourhoods", hash: 'neighbourhoods', component: Views::Admin::Sites::FormTabNeighbourhoods },
          { label: "\u{1F3F7}\u{FE0F} Partnerships", hash: 'partnerships', component: Views::Admin::Sites::FormTabPartnerships },
          { label: "\u{1F441}\u{FE0F} Preview", hash: 'preview', component: Views::Admin::Sites::FormTabPreview, persisted_only: true },
          { label: "\u{2699}\u{FE0F} Settings", hash: 'settings', component: Views::Admin::Sites::FormTabSettings, spacer_before: true }
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
