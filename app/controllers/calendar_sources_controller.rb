# frozen_string_literal: true

# The public list of calendar sources, read by the handbook's build
class CalendarSourcesController < ApplicationController
  SCHEMA_VERSION = 1
  CACHE_TTL = 1.hour

  skip_before_action :set_supporters
  skip_before_action :set_navigation

  def index
    expires_in CACHE_TTL, public: true
    render json: { version: SCHEMA_VERSION, fields:, tiers:, sources: }
  end

  private

  def fields
    CalendarImporter::Events::Base::FIELDS.keys.map do |field|
      { key: field, label: t("admin.calendars.sources.fields.#{field}") }
    end
  end

  def tiers
    CalendarImporter::Parsers::Base::TIERS.map do |tier|
      { key: tier, label: t("admin.calendars.sources.tiers.#{tier}.label"),
        description: t("admin.calendars.sources.tiers.#{tier}.description") }
    end
  end

  def sources
    CalendarImporter::CalendarImporter.public_parsers.sort_by { it::NAME.downcase }.map(&:as_source)
  end
end
