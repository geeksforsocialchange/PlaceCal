# frozen_string_literal: true

# Which events belong to a site: the membership rule, separate from the
# filtering, counting and grouping EventsQuery does on top of it. Both site
# shapes take events organised by, or hosted at, a site partner; a
# neighbourhood site also takes events at an address in its area, and a tagged
# site adds the legacy venue match.
class SiteEventsScope
  def initialize(site:)
    @site = site
  end

  # @return [ActiveRecord::Relation<Event>]
  def call
    @site.tags.any? ? tagged : untagged
  end

  private

  # Handed to Postgres as a literal id list: as a subquery the planner hashed
  # the set and scanned every future event per count (600ms against 12ms on
  # production data, four counts a page). Ids only, never partner rows.
  def partner_ids
    @partner_ids ||= PartnersQuery.new(site: @site).call.reorder(nil).except(:includes).pluck(:id)
  end

  def untagged
    base = Event.left_joins(:address)
    base.where(organiser_id: partner_ids)
        .or(base.where(place_id: partner_ids))
        .or(base.where(addresses: { neighbourhood_id: @site.owned_neighbourhood_ids }))
  end

  def tagged
    return Event.none if partner_ids.empty?

    base = Event.left_joins(:address)
    base.where(organiser_id: partner_ids)
        .or(base.where(place_id: partner_ids))
        .or(base.where(legacy_venue_match_sql))
  end

  # From 2024 (commit 5b90f19): an event with no place counts as held at a
  # partner when its address street line is the partner's name and the
  # postcodes agree.
  def legacy_venue_match_sql
    <<~SQL.squish
      EXISTS (SELECT 1 FROM partners venue_partners
        INNER JOIN addresses venue_addresses ON venue_addresses.id = venue_partners.address_id
        WHERE venue_partners.id IN (#{partner_ids.map(&:to_i).join(',')})
        AND lower(venue_partners.name) = lower(addresses.street_address) AND lower(venue_addresses.postcode) = lower(addresses.postcode))
    SQL
  end
end
