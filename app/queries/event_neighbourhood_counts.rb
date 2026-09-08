# frozen_string_literal: true

# The neighbourhood filter dropdown for a site's events: every neighbourhood
# with events in its subtree, each with that subtree's count, sorted by name.
# Given a period- and region-filtered events relation, rolls the counts up to
# the ancestors within the site's own territory.
class EventNeighbourhoodCounts
  def initialize(scope:, site:)
    @scope = scope
    @site = site
  end

  # @return [Array<Hash>] { neighbourhood:, count: }
  def call
    site_root_ids = @site.neighbourhoods.pluck(:id)
    return [] if site_root_ids.empty?

    dropdown_neighbourhoods(raw_counts, site_root_ids)
  end

  private

  # Events per neighbourhood they happen in, in one query.
  def raw_counts
    @scope
      .left_joins(:address, organiser: :address)
      .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IS NOT NULL')
      .group('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id)')
      .distinct
      .count
  end

  # Only neighbourhoods with events and their ancestors can carry a count, so
  # load just those, not every descendant of the site: a country-anchored site
  # has ~13,000 descendants and loading them all to fill a short dropdown cost
  # ~2s. Kept to strict descendants of the site's neighbourhoods, so the anchor
  # nodes are excluded, as before.
  def dropdown_neighbourhoods(raw_counts, site_root_ids)
    return [] if raw_counts.empty?

    event_hoods = Neighbourhood.where(id: raw_counts.keys).to_a
    candidate_ids = (raw_counts.keys + event_hoods.flat_map(&:ancestor_ids)).uniq

    Neighbourhood.where(id: candidate_ids).order(:name).filter_map do |node|
      next unless (node.ancestor_ids & site_root_ids).any?

      count = event_hoods.sum { |h| h.path_ids.include?(node.id) ? raw_counts[h.id] : 0 }
      { neighbourhood: node, count: count } if count.positive?
    end
  end
end
