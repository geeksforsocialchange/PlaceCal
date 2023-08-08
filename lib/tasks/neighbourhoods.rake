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

  def load_csv(release_date, file_name)
    log "  loading from #{file_name}"
    year_prefix = release_date.year % 100

    full_path = Rails.root.join("lib/data/#{file_name}")
    CSV.foreach(full_path, headers: true) do |row|
      parent_ons_id = nil

      # country
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'country', "CTRY#{year_prefix}CD", "CTRY#{year_prefix}NM")

      # region
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'region', "RGN#{year_prefix}CD", "RGN#{year_prefix}NM")

      # county
      parent_ons_id = process_row(row, release_date, parent_ons_id, 'county', "CTY#{year_prefix}CD", "CTY#{year_prefix}NM")

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

    # 3. for each neighbourhood, figure out its parent relationship, save it to database
    log 'Saving neighbourhoods'
    save_missing_neighbourhoods

    # 4. update neighbourhoods with parents and save
    log 'Reparenting neighbourhoods'
    reparent_neighbourhoods
  end
end

module BulkPostcodeDownloader
  module_function

  API_URL = 'https://api.postcodes.io/postcodes'
  HEADERS = {
    'Content-Type': 'application/json'
  }.freeze

  BATCH_SIZE = 50
  SLEEP_PERIOD = 2
  DUMP_FILE_NAME = 'address-postcodes-lookup.json'

  def find_address_postcodes
    puts 'Reading address postcodes'

    found = Address
            .distinct(:postcode)
            .pluck(:postcode)
            .map { |value| value.to_s.gsub(/\s+/, '').upcase }

    found.each do |postcode|
      @postcodes[postcode] = true
    end
    puts "  found #{@postcodes.count} unique postcodes in DB"
  end

  def lookup_postcodes
    puts 'Lookup up postcodes from postcodes.io'

    @postcodes.keys.in_groups_of(BATCH_SIZE) do |postcode_batch|
      postcode_batch.keep_if(&:present?)
      puts "  #{postcode_batch.to_json}"
      break if postcode_batch.empty?

      body = {
        postcodes: postcode_batch
      }.to_json

      response = HTTParty.post(API_URL, body: body, headers: HEADERS)
      payload = JSON.parse(response.body)

      result = payload['result']

      result.each do |result_response|
        postcode = result_response['query']

        pc_result = result_response['result']
        next unless pc_result

        @postcodes[postcode] = pc_result
      end

      sleep SLEEP_PERIOD
    end
  end

  def save_results
    puts 'Saving results'
    dump_file_path = Rails.root.join('tmp', DUMP_FILE_NAME)
    puts "  to #{dump_file_path}"
    File.open(dump_file_path, 'w').puts(@postcodes.to_json)
  end

  def run
    @postcodes = {}

    find_address_postcodes

    lookup_postcodes

    save_results

    puts 'done.'
  end
end

module AddressPostcodeVerifier
  module_function

  def run
    puts 'Address Postcode verifier'

    dump_file_path = Rails.root.join('tmp', BulkPostcodeDownloader::DUMP_FILE_NAME)
    puts "  loading from #{dump_file_path}"

    postcode_data = JSON.parse(File.read(dump_file_path))
    puts "  read #{postcode_data.count} postcodes"

    postcode_data.each do |postcode, response|
      unless response.is_a?(Hash)
        puts "  '#{postcode}' not found in postcodes.io response"
        next
      end

      # puts "#{postcode} -> #{response.to_json}"
      found = Neighbourhood.find_from_postcodesio_response(response)
      if found.nil?
        puts "  '#{postcode}' not found in neighbourhood"

      else
        puts "  '#{postcode}' -> #{found.release_date.year}"
      end
    end
  end
end

module SiteRelationSnapshotter
  module_function

  DUMP_FILE_NAME = 'site-relations.json'

  def capture_site_relations(site)
    puts "  #{site.id} #{site.name}"
    payload = { site: site.as_json }

    payload[:primary_neighbourhood] = site.primary_neighbourhood&.id
    payload[:neighbourhoods] = site.neighbourhoods.pluck(:id)

    site_neighbourhood_ids = site.owned_neighbourhood_ids
    payload[:all_neighbourhoods] = site_neighbourhood_ids
    puts '    warning: site has no neighbourhoods' if site_neighbourhood_ids.empty?

    @sites << payload
  end

  def save_relation_data
    full_path = Rails.root.join('tmp', DUMP_FILE_NAME)
    puts "  saving to #{full_path}"

    File.open(full_path, 'w').puts(@sites.to_json)
  end

  def run
    @sites = []

    puts 'Site relation snap-shotter'
    found = Site.order(:name)
    puts "  found #{found.count} sites"

    found.all.each do |site|
      capture_site_relations site
    end

    save_relation_data
  end
end

module SiteRelationVerifier
  module_function

  def load_previous_sites
    dump_file_path = Rails.root.join('tmp', SiteRelationSnapshotter::DUMP_FILE_NAME)
    puts "  loading from #{dump_file_path}"

    @previous_sites = JSON.parse(File.read(dump_file_path))
    puts "  read #{@previous_sites.count} sites"
  end

  def verify_top_level_neighbourhoods(site, site_data)
    old_neighbourhoods = Set.new(site_data['neighbourhoods'])
    new_neighbourhoods = Set.new(site.neighbourhoods.pluck(:id))

    # important! the update should never touch a sites direct neighbourhoods!

    return if old_neighbourhoods == new_neighbourhoods

    puts '    warning! miss-matched site top level neighbourhoods'
    # neighbourhoods that are only in the old set
    neighbourhoods_removed = old_neighbourhoods - new_neighbourhoods
    puts "      neighbourhoods_removed=#{neighbourhoods_removed.to_json}"

    # neighbourhoods that are only in the new set
    neighbourhoods_added = new_neighbourhoods - old_neighbourhoods
    puts "      neighbourhoods_added=#{neighbourhoods_added.to_json}"
  end

  def verify_all_neighbourhoods(site, site_data)
    all_old_neighbourhoods = Set.new(site_data['all_neighbourhoods'])
    # puts "    old_neighbourhoods=#{old_neighbourhoods.count}"

    all_new_neighbourhoods = Set.new(site.owned_neighbourhood_ids)
    # puts "    new_neighbourhoods=#{new_neighbourhoods.count}"

    # neighbourhoods that are only in the old set
    all_neighbourhoods_removed = all_old_neighbourhoods - all_new_neighbourhoods
    puts "    WARNING: all_hoods_removed.count=#{all_neighbourhoods_removed.count}" if all_neighbourhoods_removed.length.positive?

    # neighbourhoods that are only in the new set
    all_neighbourhoods_added = all_new_neighbourhoods - all_old_neighbourhoods
    puts "    all_neighbourhoods_added.count=#{all_neighbourhoods_added.count}" if all_neighbourhoods_added.count.positive?
  end

  def verify_site(site_data)
    site = Site.find(site_data['site']['id'])
    puts "  #{site.name}"

    verify_top_level_neighbourhoods site, site_data

    verify_all_neighbourhoods site, site_data
  end

  def run
    require 'set'

    puts 'Site relation verifier'

    load_previous_sites

    @previous_sites.each do |site_data|
      verify_site site_data
    end
  end
end

namespace :neighbourhoods do
  desc 'find or create all available neighbourhoods'
  task import: :environment do
    NeighbourhoodImporter.run
  end

  desc 'looks up every address postcode and saves the result'
  task bulk_lookup_address_postcodes: :environment do
    BulkPostcodeDownloader.run
  end

  desc 'verifies postcode.io response maps to our internal neighbourhoods'
  task verify_address_postcodes: :environment do
    AddressPostcodeVerifier.run
  end

  desc 'captures sites and their neighbourhoods'
  task capture_site_relations: :environment do
    SiteRelationSnapshotter.run
  end

  desc 'verifies sites have acceptable neighbourhood sets'
  task verify_site_neighbourhoods: :environment do
    SiteRelationVerifier.run
  end

  # we could have a task that scans for neighbourhoods that don't sit in the
  # latest version and lists which partners/sites are still linking through
  # them and/or prune unused obsolete neighbourhoods
end
