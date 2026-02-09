# frozen_string_literal: true

require 'yaml'
require 'geocoder/lookups/base'
require 'geocoder/results/postcodes_io'

module Geocoder
  module Lookup
    class NormalIsland < Base
      def name
        'NormalIsland'
      end

      def search(query, options = {})
        query = Geocoder::Query.new(query, options) unless query.is_a?(Geocoder::Query)
        postcode = normalize_postcode(query.text)

        local_data = local_result_for(postcode)
        return local_data.map { |d| Geocoder::Result::PostcodesIo.new(d) } if local_data

        # Delegate to postcodes.io for real UK postcodes
        postcodes_io_lookup.search(query)
      end

      private

      def normalize_postcode(text)
        text.to_s.upcase.gsub(/\s+/, ' ').strip
      end

      def normal_island_postcode?(postcode)
        postcode.match?(/\AZZ[A-Z]{2}\s*\d[A-Z]{2}\z/i)
      end

      def local_result_for(postcode)
        # Check Normal Island postcodes (ZZ-prefix)
        return normal_island_result(postcode) if normal_island_postcode?(postcode)

        # Check supplementary postcodes (Manchester, invalid, etc.)
        supplementary = supplementary_result(postcode)
        return supplementary if supplementary

        # In test environment, return the default stub for unknown postcodes
        # so tests don't hit the real API
        return default_stub_result(postcode) if Rails.env.test?

        # Not a local postcode — return nil to trigger postcodes.io delegation
        nil
      end

      def normal_island_result(postcode)
        normalized = postcode.gsub(/\s+/, ' ').strip
        ward_key = ::NormalIsland::POSTCODES[normalized]

        unless ward_key
          # Valid ZZ-prefix pattern but not in our data (like ZZXX 0XX)
          # Check supplementary postcodes for explicit entries
          return supplementary_result(postcode)
        end

        ward = ::NormalIsland::WARDS[ward_key]
        address = ::NormalIsland::ADDRESSES[ward_key]
        hierarchy = ::NormalIsland.ward_hierarchy(ward_key)

        [build_response(normalized, ward, address, hierarchy)]
      end

      def build_response(postcode, ward, address, hierarchy)
        {
          'postcode' => postcode,
          'quality' => 1,
          'eastings' => (address[:longitude].abs * 100_000).to_i,
          'northings' => (address[:latitude].abs * 100_000).to_i,
          'country' => 'Normal Island',
          'longitude' => address[:longitude],
          'latitude' => address[:latitude],
          'region' => hierarchy[:region][:name],
          'admin_district' => hierarchy[:district][:name],
          'admin_county' => hierarchy[:county][:name],
          'admin_ward' => ward[:name],
          'codes' => {
            'admin_district' => hierarchy[:district][:unit_code_value],
            'admin_county' => hierarchy[:county][:unit_code_value],
            'admin_ward' => ward[:unit_code_value]
          }
        }
      end

      def supplementary_result(postcode)
        normalized = postcode.gsub(/\s+/, '').strip
        normalized_with_space = postcode.gsub(/\s+/, ' ').strip

        supplementary_postcodes.each do |key, entry|
          next if key == 'default'

          postcodes = entry['postcodes'] || []

          match = postcodes.any? { |p| p.gsub(/\s+/, '') == normalized }
          next unless match

          data = entry['data']
          return [] if data.nil?

          result = data.dup
          result['postcode'] = normalized_with_space
          return [result]
        end

        nil
      end

      def default_stub_result(postcode)
        default = supplementary_postcodes['default']
        return nil unless default

        data = default['data']
        return nil if data.nil?

        result = data.dup
        result['postcode'] = postcode
        [result]
      end

      def supplementary_postcodes
        @supplementary_postcodes ||= YAML.load_file(
          File.expand_path('supplementary_postcodes.yml', __dir__)
        )
      end

      def postcodes_io_lookup
        @postcodes_io_lookup ||= Geocoder::Lookup::PostcodesIo.new
      end

      # Required by Base but unused since we override search directly
      def results(_query)
        []
      end
    end
  end
end
