# frozen_string_literal: true

# Headline counts: partnerships, partners, events this month, districts.
class DirectoryStatsQuery
  CACHE_KEY = 'directory/stats'
  CACHE_OPTIONS = { expires_in: 1.day, race_condition_ttl: 30.seconds }.freeze

  # One cache entry shared by both homepages, so they quote the same numbers.
  # @return [Hash] counts keyed by :partnerships, :partners, :events, :neighbourhoods
  def self.fetch_cached
    Rails.cache.fetch(CACHE_KEY, **CACHE_OPTIONS) { new.call }
  end

  # @return [Hash] counts keyed by :partnerships, :partners, :events, :neighbourhoods
  def call
    {
      partnerships: Site.where(is_published: true).count,
      partners: Partner.visible.count,
      events: Event.where(dtstart: Time.zone.today..30.days.from_now).count,
      neighbourhoods: Neighbourhood.districts.count
    }
  end
end
