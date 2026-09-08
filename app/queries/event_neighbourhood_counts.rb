# frozen_string_literal: true

# The neighbourhood filter dropdown for a site's events listing: every
# neighbourhood that has events somewhere in its subtree, each carrying that
# subtree's event count, sorted by name.
#
# Given an already period- and region-filtered events relation, it counts the
# events per neighbourhood and rolls those up to the ancestors within the
# site's own territory. Extracted from EventsQuery to keep that object focused
# on selecting events (app/queries, single responsibility).
class EventNeighbourhoodCounts
  # @param scope [ActiveRecord::Relation<Event>] the events to count, already
  #   filtered by period and any region
  # @param site [Site] the site whose neighbourhoods bound the dropdown
  def initialize(scope:, site:)
    @scope = scope
    @site = site
  end

  # @return [Array<Hash>] { neighbourhood: Neighbourhood, count: Integer }
  def call
    site_root_ids = @site.neighbourhoods.pluck(:id)
    return [] if site_root_ids.empty?

    dropdown_neighbourhoods(raw_counts, site_root_ids)
  end

  private

  # Events counted against the neighbourhood they happen in (single query).
  #
  # @return [Hash{Integer=>Integer}] event count per neighbourhood id
  def raw_counts
    @scope
      .left_joins(:address, organiser: :address)
      .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IS NOT NULL')
      .group('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id)')
      .distinct
      .count
  end

  # Only the neighbourhoods that have events and their ancestors can carry a
  # non-zero count, so we load just those rather than every descendant of the
  # site. A country-anchored site has ~13,000 descendants; loading them all to
  # fill a handful-long dropdown cost ~2s a request. Entries are kept to strict
  # descendants of the site's own neighbourhoods, so the anchor nodes are
  # excluded, matching the previous descendants-only behaviour.
  #
  # @param raw_counts [Hash{Integer=>Integer}] event count per neighbourhood id
  # @param site_root_ids [Array<Integer>] the site's own neighbourhood ids
  # @return [Array<Hash>] { neighbourhood:, count: } sorted by name
  def dropdown_neighbourhoods(raw_counts, site_root_ids)
    return [] if raw_counts.empty?

    event_hoods = Neighbourhood.where(id: raw_counts.keys).to_a
    candidate_ids = (raw_counts.keys + event_hoods.flat_map(&:ancestor_ids)).uniq

    Neighbourhood.where(id: candidate_ids).order(:name).filter_map do |node|
      next unless (node.ancestor_ids & site_root_ids).any?

      # An event counts towards a node when the node is an ancestor-or-self of
      # the neighbourhood the event is in, i.e. the event sits in its subtree.
      count = event_hoods.sum { |h| h.path_ids.include?(node.id) ? raw_counts[h.id] : 0 }
      { neighbourhood: node, count: count } if count.positive?
    end
  end
end
