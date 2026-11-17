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
    parsers.sort_by { |parser| parser::NAME }.map { |parser| [parser::NAME, parser::DOMAINS] }
  end
end
