# frozen_string_literal: true

require_relative 'lib/pancal/version'

Gem::Specification.new do |spec|
  spec.name = 'pancal'
  spec.version = PanCal::VERSION
  spec.authors = ['Geeks for Social Change']
  spec.email = ['support@gfsc.studio']

  spec.summary = 'Pandoc for events: convert messy event sources into standardised schema.org or iCal data'
  spec.description = 'PanCal reads event feeds from many messy sources (iCal, Eventbrite, ' \
                     'LD+JSON, TicketSource, and more) into a canonical event format, ' \
                     'from which standard formats (schema.org JSON-LD, iCalendar) can be written.'
  spec.homepage = 'https://github.com/geeksforsocialchange/PlaceCal'
  spec.license = 'LGPL-3.0-or-later'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'exe/*', 'README.md', 'LICENSE*']
  spec.bindir = 'exe'
  spec.executables = []
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'base64' # not a default gem on Ruby >= 3.4; used by ApiBase
  spec.add_dependency 'eventbrite_sdk'
  spec.add_dependency 'httparty'
  spec.add_dependency 'icalendar'
  spec.add_dependency 'icalendar-recurrence'
  spec.add_dependency 'json-ld'
  spec.add_dependency 'kramdown'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'rails-html-sanitizer'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'uk_postcode'
end
