# frozen_string_literal: true

class Views::Admin::Calendars::Form < Views::Admin::Base
  prop :calendar, Calendar, reader: :private

  def view_template # rubocop:disable Metrics/MethodLength
    render Views::Admin::Calendars::ImporterOverview.new(calendar: calendar) unless calendar.new_record?

    simple_form_for([:admin, calendar], html: { data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'calendarTabAfterSave' } }) do |form|
      div(class: 'mt-6') do
        TabForm(
          tabs: [
            { label: "\u{1F4E5} Source", hash: 'source', component: Views::Admin::Calendars::FormTabSource },
            { label: "\u{1F4CD} Location", hash: 'location', component: Views::Admin::Calendars::FormTabLocation },
            { label: "\u{1F4DE} Contact", hash: 'contact', component: Views::Admin::Calendars::FormTabContact },
            { label: "\u{1F441}\u{FE0F} Preview", hash: 'preview', component: Views::Admin::Calendars::FormTabPreview, persisted_only: true },
            { label: "\u{2699}\u{FE0F} Settings", hash: 'settings', component: Views::Admin::Calendars::FormTabSettings, persisted_only: true, spacer_before: true }
          ],
          tab_name: 'calendar_tabs',
          storage_key: 'calendarTabAfterSave',
          settings_hash: 'settings',
          preview_hash: 'preview',
          form: form,
          record: calendar
        )
      end
    end
  end
end
