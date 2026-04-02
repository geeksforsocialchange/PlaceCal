# frozen_string_literal: true

# Provides a `permalink(base_url:)` method that builds a canonical URL
# for any model. Follows the same `base_url:` pattern as the JSON-LD
# concerns (EventJsonLd, PartnerJsonLd, SiteJsonLd).
#
# Usage:
#   class Event < ApplicationRecord
#     include Permalinkable
#     permalink_resource 'events'
#   end
#
#   # Default: uses the default site's URL (https://placecal.org)
#   event.permalink  # => "https://placecal.org/events/42"
#
#   # With site context: pass the site's URL for subdomain-aware links
#   event.permalink(base_url: site.url)  # => "https://mossley.placecal.org/events/42"
module Permalinkable
  extend ActiveSupport::Concern

  class_methods do
    def permalink_resource(resource_name)
      define_method(:permalink) do |base_url: nil|
        base_url ||= Site.find_by(slug: 'default-site')&.url || 'https://placecal.org'
        "#{base_url.chomp('/')}/#{resource_name}/#{id}"
      end
    end
  end
end
