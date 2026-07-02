# frozen_string_literal: true

# Headline numbers shared by the nationwide directory homepage and the join
# marketing site: live partnerships, visible partners, events over the next
# month, and districts covered. Callers wrap this in Rails.cache (both use the
# 'directory/stats' key so the two homepages stay in sync).
#
# @example
#   DirectoryStatsQuery.new.call
#   # => { partnerships: 10, partners: 413, events: 918, neighbourhoods: 42 }
#
class DirectoryStatsQuery
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
