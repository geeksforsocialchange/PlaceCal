# frozen_string_literal: true

# After a new ONS release is imported (neighbourhoods:import), wards that were
# redrawn get brand-new Neighbourhood rows and the old rows become legacy.
# addresses:regeocode re-points addresses at the new rows, but nothing updates
# the other three tables that reference neighbourhoods — so sites silently stop
# matching partners (e.g. the Mossley site after the May 2024 Tameside redraw).
#
# This remaps sites_neighbourhoods, service_areas and neighbourhoods_users rows
# that still point at an old-release neighbourhood to its latest-release
# replacement, matched by code or by unit + name + parent name. Anything
# ambiguous or unmatched is reported for manual review rather than guessed.
module NeighbourhoodRemapper
  module_function

  # model class name => the column its neighbourhood_id uniqueness is scoped to
  ASSOCIATIONS = {
    'SitesNeighbourhood' => :site_id,
    'ServiceArea' => :partner_id,
    'NeighbourhoodsUser' => :user_id
  }.freeze

  # @param dry_run [Boolean] report what would change without writing
  # @return [Hash] counts of remapped/deleted rows and skipped row labels
  def run(dry_run: false)
    @dry_run = dry_run
    @summary = { remapped: 0, deleted: 0, skipped: [] }
    replacements = {}

    log 'DRY RUN - no changes will be made' if @dry_run

    ASSOCIATIONS.each do |model_name, scope_column|
      model = model_name.constantize

      stale_rows(model).find_each do |row|
        old = row.neighbourhood
        replacement = (replacements[old.id] ||= find_replacement(old))

        if replacement.is_a?(Neighbourhood)
          remap_row(model, row, scope_column, old, replacement)
        else
          log "  SKIP #{model_name}##{row.id}: #{old.contextual_name} [#{old.unit_code_value}] - #{replacement}"
          @summary[:skipped] << "#{model_name}##{row.id}"
        end
      end
    end

    refresh_counts_if_changed

    log "Done: #{@summary[:remapped]} remapped, #{@summary[:deleted]} duplicates removed, " \
        "#{@summary[:skipped].length} skipped for manual review"
    @summary
  end

  # @param model [Class] one of the ASSOCIATIONS join models
  # @return [ActiveRecord::Relation] rows pointing at pre-latest-release neighbourhoods
  def stale_rows(model)
    model.joins(:neighbourhood)
         .where(neighbourhoods: { release_date: ...Neighbourhood::LATEST_RELEASE_DATE })
  end

  # Find the latest-release neighbourhood that replaces an old one.
  # @param old [Neighbourhood]
  # @return [Neighbourhood, String] the replacement, or a reason to skip
  def find_replacement(old)
    candidates = Neighbourhood.latest_release.where(unit: old.unit)

    # Codes are stable across releases unless boundaries changed, so an exact
    # code match (e.g. an old row the importer never bumped) is safest.
    by_code = candidates.where(unit_code_value: old.unit_code_value)
    return by_code.first if by_code.one?

    by_name = candidates.where('lower(name) = ?', old.name.to_s.downcase).to_a
    same_parent = by_name.select { |c| c.parent&.name == old.parent&.name }

    return same_parent.first if same_parent.length == 1
    return by_name.first if by_name.length == 1
    return "ambiguous: #{by_name.length} candidates named #{old.name.inspect}" if by_name.length > 1

    'no match in latest release'
  end

  # @return [void]
  def remap_row(model, row, scope_column, old, replacement)
    owner = "#{scope_column}=#{row[scope_column]}"

    survivor = model.find_by(scope_column => row[scope_column], :neighbourhood_id => replacement.id)
    if survivor
      # The owner is already linked to the replacement; the stale row is a duplicate.
      log "  DELETE #{model.name}##{row.id} (#{owner}): already linked to #{replacement.contextual_name}"
      unless @dry_run
        row.destroy
        promote_survivor(row, survivor)
      end
      @summary[:deleted] += 1
    else
      log "  REMAP #{model.name}##{row.id} (#{owner}): #{old.contextual_name} -> " \
          "#{replacement.contextual_name} [#{replacement.unit_code_value}]"
      row.update_columns(neighbourhood_id: replacement.id) unless @dry_run # rubocop:disable Rails/SkipsModelValidations
      @summary[:remapped] += 1
    end
  end

  # Deleting a stale Primary site link must not leave the site with only
  # Secondary neighbourhoods — hand the Primary slot to the surviving row.
  # @return [void]
  def promote_survivor(deleted_row, survivor)
    return unless deleted_row.is_a?(SitesNeighbourhood)
    return unless deleted_row.relation_type == 'Primary' && survivor.relation_type != 'Primary'

    log "  PROMOTE #{survivor.class.name}##{survivor.id}: relation_type -> Primary"
    survivor.update_columns(relation_type: 'Primary') # rubocop:disable Rails/SkipsModelValidations
  end

  # update_columns skips ServiceArea's cache-invalidation callback, so refresh
  # the cached partner counts in one pass at the end instead.
  # @return [void]
  def refresh_counts_if_changed
    return if @dry_run
    return unless @summary[:remapped].positive? || @summary[:deleted].positive?

    Neighbourhood.refresh_partners_count!
  end

  # @return [void]
  def log(msg)
    $stdout.puts msg
  end
end
