# frozen_string_literal: true

# Which events belong to a site: the membership rule, separate from the
# filtering, counting and grouping that EventsQuery does on top of it.
#
# Both site shapes take events organised by, or hosted at, one of the site's
# partners. A neighbourhood site also takes any event whose address is in its
# area; a tagged site adds the legacy venue match. The hosted-at rule reaches
# an event a site partner puts on somewhere else, the same way the partner
# page and the tag filter count it.
class SiteEventsScope
  # @param site [Site]
  def initialize(site:)
    @site = site
  end

  # @return [ActiveRecord::Relation<Event>]
  def call
    @site.tags.any? ? tagged : untagged
  end

  private

  # The site's partner ids, handed to Postgres as a literal list. As a subquery
  # the planner hashed the set and scanned every future event for each count
  # (600ms against 12ms on production data, four counts per events page). Ids
  # only, never partner rows.
  def partner_ids
    @partner_ids ||= PartnersQuery.new(site: @site).call.reorder(nil).except(:includes).pluck(:id)
  end

  # For sites without tags: partner events plus anything at a site address.
  def untagged
    base = Event.left_joins(:address)
    base.where(organiser_id: partner_ids)
        .or(base.where(place_id: partner_ids))
        .or(base.where(addresses: { neighbourhood_id: @site.owned_neighbourhood_ids }))
  end

  # For sites with tags: events organised by, or hosted at, a site partner,
  # plus the legacy venue match.
  def tagged
    return Event.none if partner_ids.empty?

    base = Event.left_joins(:address)
    base.where(organiser_id: partner_ids)
        .or(base.where(place_id: partner_ids))
        .or(base.where(legacy_venue_match_sql))
  end

  # Legacy venue matching, from 2024 (commit 5b90f19), for events whose place
  # was never set: an event counts as happening at a partner when its address
  # street line is the partner's name and the postcodes agree. Ids are cast to
  # integers again before interpolation.
  def legacy_venue_match_sql
    <<~SQL.squish
      EXISTS (SELECT 1 FROM partners venue_partners
        INNER JOIN addresses venue_addresses ON venue_addresses.id = venue_partners.address_id
        WHERE venue_partners.id IN (#{partner_ids.map(&:to_i).join(',')})
        AND lower(venue_partners.name) = lower(addresses.street_address) AND lower(venue_addresses.postcode) = lower(addresses.postcode))
    SQL
  end
end
