# frozen_string_literal: true

class Views::Admin::Partners::Form < Views::Admin::Base
  prop :partner, Partner, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    simple_form_for(partner, html: { data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'partnerTabAfterSave' } }) do |form|
      if helpers.policy(partner).permitted_attributes.exclude?(:hidden) && partner.hidden
        div(role: 'alert', class: 'alert alert-error mb-6') do
          raw icon(:warning, size: '6', css_class: 'shrink-0')
          div do
            h3(class: 'font-bold') { 'This partner is hidden' }
            p { 'Your partner is currently not visible to the public for the following reason:' }
            div(class: 'mt-2 p-3 bg-error/20 rounded') { raw safe(partner.hidden_reason_html.to_s) }
            p(class: 'mt-2') do
              plain 'Once you have fixed this issue, contact '
              a(href: 'mailto:support@placecal.org', class: 'link') { 'support@placecal.org' }
              plain ' to make your partner public again.'
            end
          end
        end
      end

      TabForm(
        tabs: [
          { label: "\u{1F4CB} Basic Info", hash: 'basic', component: Views::Admin::Partners::FormTabBasic },
          { label: "\u{1F4CD} Location", hash: 'location', component: Views::Admin::Partners::FormTabLocation },
          { label: "\u{1F4DE} Contact", hash: 'contact', component: Views::Admin::Partners::FormTabContact },
          { label: "\u{1F3F7}\u{FE0F} Tags", hash: 'tags', component: Views::Admin::Partners::FormTabTags },
          { label: "\u{1F4C5} Calendars", hash: 'calendars', component: Views::Admin::Partners::FormTabCalendars, persisted_only: true },
          { label: "\u{1F465} Admins", hash: 'admins', component: Views::Admin::Partners::FormTabAdmins, persisted_only: true },
          { label: "\u{1F441}\u{FE0F} Preview", hash: 'preview', component: Views::Admin::Partners::FormTabPreview, persisted_only: true },
          { label: "\u{2699}\u{FE0F} Settings", hash: 'settings', component: Views::Admin::Partners::FormTabSettings, spacer_before: true }
        ],
        tab_name: 'partner_tabs',
        storage_key: 'partnerTabAfterSave',
        settings_hash: 'settings',
        preview_hash: 'preview',
        form: form,
        record: partner
      )
    end
  end
end
