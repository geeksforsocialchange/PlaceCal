# frozen_string_literal: true

# Exports the calendar parsers' URL detection rules as a JSON-friendly hash
# for the browser extension (via /api/v1/calendar_detection_rules), so the
# extension and the Rails importer share a single source of truth. Patterns
# come from each parser's URL_PATTERNS, which are declared in the shared
# Ruby/JavaScript regex subset (see CalendarImporter::Parsers::Base).
class CalendarDetectionRules
  # Bump when the shape of the payload changes incompatibly; the extension
  # rejects versions it doesn't understand.
  SCHEMA_VERSION = 1

  def self.as_json
    {
      version: SCHEMA_VERSION,
      parsers: CalendarImporter::CalendarImporter::PARSERS
               .select { |parser| parser::PUBLIC }
               .map { |parser| parser_json(parser) }
    }
  end

  def self.parser_json(parser)
    {
      key: parser::KEY,
      name: parser::NAME,
      domains: parser::DOMAINS,
      url_patterns: parser.url_patterns,
      requires_api_token: parser.requires_api_token?,
      content_detection: parser.content_detection
    }
  end
end
