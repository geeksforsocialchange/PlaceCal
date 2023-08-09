# frozen_string_literal: true

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

namespace :placecal do
  desc 'Creates the default set of PHT category tags'
  task load_pht_category_tags: :environment do
    categories = [
      'Activism',
      'Arts & Crafts',
      'Children & Family',
      'Young Adults',
      'Over 50s',
      'Entertainment',
      'Education',
      'Food',
      'Health & Wellbeing',
      'Outdoors',
      'Sports & Fitness',
      'Places of Worship',
      'Community Hubs',
      'Housing',
      'Legal Advice',
      'Immigration',
      'LGBTQ+',
      'Communities of Colour'
    ]

    categories.each do |category|
      puts category
      Category.find_or_create_by!(name: category)
    end
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
