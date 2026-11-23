# frozen_string_literal: true

module CalendarsHelper
  def options_for_organiser
    policy_scope(Partner).order(:name)
  end

  def options_for_location
    policy_scope(Partner)
      .with_address
      .order(:name)
  end

  def options_for_importer
    parsers = CalendarImporter::CalendarImporter.public_parsers
    parsers.map { |parser| [parser::NAME, parser::KEY] }.prepend(['(Auto detect)', 'auto'])
  end

  def calendar_source_data
    notices = %w[google eventbrite luma].index_with { t("admin.calendars.wizard.source.rewritten.#{it}") }
    {
      controller: 'calendar-source',
      'calendar-source-resolve-url-value': resolve_source_admin_calendars_path,
      'calendar-source-notices-value': notices.to_json
    }
  end

  def source_test_labels
    scope = 'admin.calendars.wizard.source'
    {
      test: t("#{scope}.test_button"),
      ok: t("#{scope}.test_ok"),
      error: t("#{scope}.test_error"),
      fallbackError: t("#{scope}.error"),
      connectionError: t("#{scope}.connection_error"),
      apiKeyHeading: t("#{scope}.api_key_heading"),
      undetectedHeading: t("#{scope}.undetected_heading"),
      undetected: t("#{scope}.undetected"),
      defaultName: t("#{scope}.default_name")
    }
  end

  def calendar_import_sources
    parsers = CalendarImporter::CalendarImporter.public_parsers
    parsers.sort_by { |parser| parser::NAME }.map do |parser|
      [parser::NAME, parser::DOMAINS.presence || [t('admin.calendars.sources.any_website')]]
    end
  end
end
