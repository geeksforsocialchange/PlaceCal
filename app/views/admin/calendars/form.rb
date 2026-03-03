# frozen_string_literal: true

class Views::Admin::Calendars::Form < Views::Admin::Base
  prop :calendar, _Any, reader: :private

  def view_template # rubocop:disable Metrics/MethodLength
    raw view_context.render('importer_overview', calendar: calendar) unless calendar.new_record?

    simple_form_for([:admin, calendar], html: { data: { controller: 'form-tabs live-validation', 'form-tabs-storage-key-value': 'calendarTabAfterSave' } }) do |form|
      div(class: 'mt-6') do
        render Components::Admin::TabForm.new(
          tabs: [
            { label: "\u{1F4E5} Source", hash: 'source', partial: 'form_tab_source' },
            { label: "\u{1F4CD} Location", hash: 'location', partial: 'form_tab_location' },
            { label: "\u{1F4DE} Contact", hash: 'contact', partial: 'form_tab_contact' },
            { label: "\u{1F441}\u{FE0F} Preview", hash: 'preview', partial: 'form_tab_preview', persisted_only: true },
            { label: "\u{2699}\u{FE0F} Settings", hash: 'settings', partial: 'form_tab_settings', persisted_only: true, spacer_before: true }
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
