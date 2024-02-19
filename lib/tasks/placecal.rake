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

  desc 'Look for obsolete neighbourhoods still referencing partners, users or sites'
  task find_obsolete_neighbourhoods: :environment do
    NeighbourhoodSweeper.run
  end

  desc 'Look for addresses with missing partners or neighbourhoods'
  task find_broken_addresses: :environment do
    partner_count = 0
    neighbourhood_count = 0

    puts 'Looking for broken addresses'
    Address.includes(:partners, :neighbourhood).all.each do |addr|
      partner_count += 1 if addr.partners.count.zero?
      neighbourhood_count += 1 if addr.neighbourhood.blank?
    end

    puts "  partner_count=#{partner_count}"
    puts "  neighbourhood_count=#{neighbourhood_count}"
  end

  # we could have a task that scans for neighbourhoods that don't sit in the
  # latest version and lists which partners/sites are still linking through
  # them and/or prune unused obsolete neighbourhoods
end

module NeighbourhoodSweeper # rubocop:disable Metrics/ModuleLength
  module_function

  def run
    @bad_users = {}
    @bad_sites = {}
    @bad_partners = {}

    puts 'Sweeping obsolete neighbourhoods'

    found = Neighbourhood.where.not(release_date: Neighbourhood::LATEST_RELEASE_DATE)

    find_obsolete_addresses found

    find_obsolete_sites found

    find_obsolete_users found

    find_obsolete_service_areas found

    report
  end

  def describe_bad_neighbourhood(outcome)
    type = 'deleted'
    type = 'replaced' if outcome[:replacement].present?
    type = 'reparented' if outcome[:reparent].present?

    hood = outcome[:neighbourhood]
    url = url_for(subdomain: 'admin', controller: 'admin/neighbourhoods', action: :show, id: hood.id)
    "**[#{hood.unit_name}](#{url})** (*#{type}*)"
  end

  def maybe_print_reparenting_info(outcome, indent)
    return if outcome[:reparent].blank?

    old_neighbourhood = outcome[:neighbourhood]
    new_neighbourhood = outcome[:reparent]
    puts "#{indent}- was: #{neighbourhood_hierarchy(old_neighbourhood)}"
    puts "#{indent}-  is: #{neighbourhood_hierarchy(new_neighbourhood)}"
  end

  def report
    puts '# Report'
    puts ''

    puts "## Users (#{@bad_users.count})"
    @bad_users.values.sort { |a, b| a[:user].email <=> b[:user].email }.each do |user|
      url = url_for(subdomain: 'admin', controller: 'admin/users', action: :edit, id: user[:user].id)
      puts "- [#{user[:user].email}](#{url})"

      user[:neighbourhoods].each do |outcome|
        puts "  - #{describe_bad_neighbourhood(outcome)}"
        maybe_print_reparenting_info outcome, '    '
      end
    end

    puts ''
    puts "## Sites (#{@bad_sites.count})"
    @bad_sites.values.sort { |a, b| a[:site].name <=> b[:site].name }.each do |site|
      url = url_for(subdomain: 'admin', controller: 'admin/sites', action: :edit, id: site[:site].id)
      puts "- [#{site[:site].name}](#{url})"

      site[:neighbourhoods].each do |outcome|
        puts "  - #{describe_bad_neighbourhood(outcome)}"
        maybe_print_reparenting_info outcome, '    '
      end
    end

    puts ''
    puts "## Partners (#{@bad_partners.count})"
    @bad_partners.values.sort { |a, b| a[:partner].name <=> b[:partner].name }.each do |partner|
      url = url_for(subdomain: 'admin', controller: 'admin/partners', action: :edit, id: partner[:partner].id)
      puts "- [#{partner[:partner].name}](#{url})"

      if partner[:address].present?
        puts '  - Address'
        partner[:address].each do |outcome|
          puts "    - #{describe_bad_neighbourhood(outcome)}"
          maybe_print_reparenting_info outcome, '      '
        end
      end

      next if partner[:service_areas].blank?

      puts '  - Service Areas'
      partner[:service_areas].each do |outcome|
        puts "    - #{describe_bad_neighbourhood(outcome)}"
        maybe_print_reparenting_info outcome, '      '
      end
    end
  end

  def found_bad_user_ref(user, old_neighbourhood, outcome = {})
    @bad_users[user.id] ||= {
      user: user,
      neighbourhoods: []
    }

    outcome[:neighbourhood] = old_neighbourhood
    @bad_users[user.id][:neighbourhoods] << outcome
  end

  def found_bad_site_ref(site, old_neighbourhood, outcome = {})
    @bad_sites[site.id] ||= {
      site: site,
      neighbourhoods: []
    }

    outcome[:neighbourhood] = old_neighbourhood
    @bad_sites[site.id][:neighbourhoods] << outcome
  end

  def found_bad_address_ref(partner, old_neighbourhood, outcome = {})
    @bad_partners[partner.id] ||= {
      partner: partner,
      address: [],
      service_areas: []
    }

    outcome[:neighbourhood] = old_neighbourhood
    @bad_partners[partner.id][:address] << outcome
  end

  def found_bad_service_area_ref(partner, old_neighbourhood, outcome = {})
    @bad_partners[partner.id] ||= {
      partner: partner,
      address: [],
      service_areas: []
    }

    outcome[:neighbourhood] = old_neighbourhood
    @bad_partners[partner.id][:service_areas] << outcome
  end

  def neighbourhood_hierarchy(hood)
    parents = neighbourhood_hierarchy(hood.parent) if hood.parent

    url = url_for(subdomain: 'admin', controller: 'admin/neighbourhoods', action: :show, id: hood.id)
    me = "**[#{hood.unit_name}](#{url})** (#{hood.unit})"

    if parents
      "#{parents} -> #{me}"
    else
      me
    end
  end

  def find_replacement_neighbourhood(old_neighbourhood)
    Neighbourhood
      .where(unit_name: old_neighbourhood.unit_name)
      .latest_release
      .first
  end

  def find_obsolete_addresses(neighbourhoods)
    puts '  Scanning addresses'

    neighbourhoods.each do |hood|
      addresses = hood.addresses
      next if addresses.empty?

      partners = addresses.reduce([]) { |found, address| found += address.partners }
      next if partners.empty?

      replacement = find_replacement_neighbourhood(hood)
      if replacement.present?
        if replacement.parent == hood.parent
          partners.each do |partner|
            found_bad_address_ref partner, hood, replacement: replacement
          end
          next
        end

        partners.each do |partner|
          found_bad_address_ref partner, hood, reparent: replacement
        end
        next
      end

      partners.each do |partner|
        found_bad_address_ref partner, hood, obsolete: true
      end
    end
  end

  def find_obsolete_sites(neighbourhoods)
    puts '  Scanning sites'

    neighbourhoods.each do |hood|
      sites = hood.sites
      next if sites.empty?

      replacement = find_replacement_neighbourhood(hood)
      if replacement.present?
        if replacement.parent == hood.parent
          sites.each do |site|
            found_bad_site_ref site, hood, replacement: replacement
          end
          next
        end

        sites.each do |site|
          found_bad_site_ref site, hood, reparent: replacement
        end
        next
      end

      sites.each do |site|
        found_bad_site_ref site, hood, obsolete: true
      end
    end
  end

  def find_obsolete_users(neighbourhoods)
    puts '  Scanning users'

    neighbourhoods.each do |hood|
      users = hood.users
      next if users.empty?

      replacement = find_replacement_neighbourhood(hood)
      if replacement.present?
        if replacement.parent == hood.parent
          users.each do |user|
            found_bad_user_ref user, hood, replacement: replacement
          end
          next
        end

        users.each do |user|
          found_bad_user_ref user, hood, reparent: replacement
        end
        next
      end

      users.each do |user|
        found_bad_user_ref user, hood, obsolete: true
      end
    end
  end

  def find_obsolete_service_areas(neighbourhoods)
    puts '  Scanning service areas'

    neighbourhoods.each do |hood|
      service_areas = hood.service_areas
      next if service_areas.empty?

      replacement = find_replacement_neighbourhood(hood)
      if replacement.present?
        if replacement.parent == hood.parent
          service_areas.each do |service_area|
            found_bad_service_area_ref service_area.partner, hood, replacement: replacement
          end
          next
        end

        service_areas.each do |service_area|
          found_bad_service_area_ref service_area.partner, hood, reparent: replacement
        end
        next
      end

      service_areas.each do |service_area|
        found_bad_service_area_ref service_area.partner, hood, obsolete: true
      end
    end
  end

  def url_for(*args)
    Rails.application.routes.url_helpers.url_for(*args)
  end
end
