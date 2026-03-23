# frozen_string_literal: true

module NeighbourhoodImporter
  module_function

  class LoaderEntry
    attr_reader :model, :ons_data, :ons_id

    def initialize(ons_id)
      @ons_id = ons_id
    end

    def model=(model_data)
      return if @model && @model.release_date >= model_data.release_date

      @model = model_data
    end

    def set_ons_data(type, ons_id_key, release_date, name, parent_ons_id)
      return if @ons_data && @ons_data[:release_date] && @ons_data[:release_date] >= release_date

      @ons_data = {
        type: type,
        ons_id_key: ons_id_key,
        release_date: release_date,
        name: name,
        parent_id: parent_ons_id
      }
    end

    def maybe_save_to_model
      return if @ons_data.nil? # nothing to update

      @model ||= Neighbourhood.new
      return if @model.release_date.present? && @model.release_date >= @ons_data[:release_date]

      @model.update!(
        name: @ons_data[:name], # human name for us
        unit_name: @ons_data[:name],
        unit: @ons_data[:type],
        level: Neighbourhood::LEVELS[@ons_data[:type].to_sym],
        unit_code_value: @ons_id,
        unit_code_key: @ons_data[:ons_id_key], # table key of ONS ID
        release_date: @ons_data[:release_date]
      )
    end

    def maybe_reparent(other_neighbourhoods)
      return if @ons_data.nil? # nothing to update

      parent_ons_id = @ons_data[:parent_id]

      parent = other_neighbourhoods[parent_ons_id]
      if parent.nil?
        NeighbourhoodImporter.log "  warning: (ONS ID '#{@ons_id}') Could not find parent. #{@ons_data.to_json} " if @ons_data[:type] != 'country'
        return
      end

      # parent is already set
      return if @model.parent_id.present? && @model.parent_id == parent.model.id

      @model.parent = parent.model
      # @model.parent_name = @model.parent.name

      @model.save!
    end
  end

  #
  # importer code
  #

  def log(msg)
    $stdout.puts msg
  end

  def load_neighbourhoods_from_db
    Neighbourhood.all.each do |hood|
      ons_id = hood.unit_code_value.to_sym

      @neighbourhoods[ons_id] ||= LoaderEntry.new(ons_id)
      @neighbourhoods[ons_id].model = hood
    end
  end

  def process_row(row_data, release_date, parent_ons_id, type, unit_code_key, unit_name_key) # rubocop:disable Metrics/ParameterLists
    unit_code = row_data[unit_code_key]
    unit_name = row_data[unit_name_key]

    # skip this level of ancestry if it doesn't exist
    return parent_ons_id if unit_code.nil?

    ons_id = unit_code.to_sym

    @neighbourhoods[ons_id] ||= LoaderEntry.new(ons_id)
    @neighbourhoods[ons_id].set_ons_data type, unit_code_key, release_date, unit_name, parent_ons_id

    ons_id # this is the parent for the next step
  end

  def load_csv(release_date, file_name, county_prefix: 'CTY')
    log "  loading from #{file_name}"
    year_prefix = release_date.year % 100

    full_path = Rails.root.join("lib/data/#{file_name}")
    CSV.foreach(full_path, headers: true) do |row|
      parent_ons_id = nil

      # country
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'country', "CTRY#{year_prefix}CD", "CTRY#{year_prefix}NM")

      # region
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'region', "RGN#{year_prefix}CD", "RGN#{year_prefix}NM")

      # county (column prefix changed from CTY to CTYUA in May 2024 ONS data)
      # For unitary authorities, CTYUA code = LAD code. Skip the county row
      # in that case so the district row creates the entry as type 'district'
      # (needed for ward.district lookups and badge display).
      # However, preserve any existing county parent from earlier imports
      # (e.g., Manchester should stay under Greater Manchester even though
      # the 2024 CTYUA data doesn't include the county relationship).
      county_code = row["#{county_prefix}#{year_prefix}CD"]
      district_code = row["LAD#{year_prefix}CD"]
      if county_code.present? && county_code == district_code
        # CTYUA == LAD: unitary authority, skip county level.
        # But if this district already has a county parent from an earlier
        # import, preserve that relationship.
        district_ons_id = district_code.to_sym
        existing = @neighbourhoods[district_ons_id]
        if existing&.ons_data
          existing_parent = @neighbourhoods[existing.ons_data[:parent_id]]
          parent_ons_id = existing.ons_data[:parent_id] if existing_parent&.ons_data && existing_parent.ons_data[:type] == 'county'
        end
      else
        parent_ons_id = process_row(row, release_date, parent_ons_id, 'county', "#{county_prefix}#{year_prefix}CD", "#{county_prefix}#{year_prefix}NM")
      end

      # district
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'district', "LAD#{year_prefix}CD", "LAD#{year_prefix}NM")

      # ward
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'ward', "WD#{year_prefix}CD", "WD#{year_prefix}NM")
    end
  end

  def save_missing_neighbourhoods
    Neighbourhood.transaction do
      @neighbourhoods.each do |_, entry|
        entry.maybe_save_to_model
      end
    end
  end

  def reparent_neighbourhoods
    Neighbourhood.transaction do
      @neighbourhoods.each do |_, entry|
        entry.maybe_reparent @neighbourhoods
      end
    end
  end

  def backfill_levels
    Neighbourhood::LEVELS.each do |unit_name, level_value|
      count = Neighbourhood.where(unit: unit_name.to_s, level: nil).update_all(level: level_value) # rubocop:disable Rails/SkipsModelValidations
      log "  set level=#{level_value} for #{count} #{unit_name} records" if count.positive?
    end
  end

  # Counties that still have latest_release descendants should themselves
  # have latest_release, even if they weren't in the latest ONS CSV
  # (e.g., Greater Manchester isn't in the 2024 CTYUA data but its
  # districts are).
  def update_county_release_dates
    Neighbourhood.where(level: 3).find_each do |county|
      latest = county.subtree.where.not(id: county.id).maximum(:release_date)
      next unless latest && (county.release_date.nil? || latest > county.release_date)

      county.update_column(:release_date, latest) # rubocop:disable Rails/SkipsModelValidations
      log "  updated #{county.name} release_date to #{latest}"
    end
  end

  def run
    @neighbourhoods = {}

    # 1. load neighbourhoods from DB.
    log 'Loading Neighbourhoods from database'
    load_neighbourhoods_from_db

    # 2. load data from CSVs
    log 'Loading CSV data'
    load_csv(
      DateTime.new(2019, 12),
      'Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(December_2019)_Lookup_in_United_Kingdom.csv'
    )

    load_csv(
      DateTime.new(2023, 5),
      'Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(May_2023)_Lookup_in_United_Kingdom.csv'
    )

    load_csv(
      DateTime.new(2024, 5),
      'Ward_to_Local_Authority_District_to_CTYUA_to_RGN_to_CTRY_(May_2024)_Lookup_in_the_UK.csv',
      county_prefix: 'CTYUA'
    )

    # 3. for each neighbourhood, figure out its parent relationship, save it to database
    log 'Saving neighbourhoods'
    save_missing_neighbourhoods

    # 4. update neighbourhoods with parents and save
    log 'Reparenting neighbourhoods'
    reparent_neighbourhoods

    # 5. backfill nil levels from unit string (for records not updated by save step)
    log 'Backfilling missing level values'
    backfill_levels

    # 6. ensure counties with latest_release descendants also have latest_release
    log 'Updating county release dates'
    update_county_release_dates
  end
end

namespace :neighbourhoods do
  desc 'find or create all available neighbourhoods'
  task import: :environment do
    NeighbourhoodImporter.run
  end
end
