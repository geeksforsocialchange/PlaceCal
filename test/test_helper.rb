# frozen_string_literal: true

require 'simplecov'
require 'vcr'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require 'webmock/minitest'
WebMock.disable_net_connect!(allow_localhost: true)

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

require 'minitest/autorun'

# JSON matcher stuff for API
require 'json_matchers/minitest/assertions'
JsonMatchers.schema_root = 'test/support/api/schemas'
Minitest::Test.send(:include, JsonMatchers::Minitest::Assertions)




class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  parallelize(workers: :number_of_processors)

  # Usage:
  #
  # it_allows_access_to_action_for(%i[root tag_admin partner_admin place_admin citizen guest]) do
  # end

  %i[index show new edit create update destroy].each do |action|
    define_singleton_method(:"it_allows_access_to_#{action}_for") do |users, &block|
      users.each do |user|
        test "#{user}: can #{action}" do
          variable = instance_variable_get("@#{user}")

          sign_in variable

          instance_exec(&block) if block
        end
      end
    end

    define_singleton_method(:"it_denies_access_to_#{action}_for") do |users, &block|
      users.each do |user|
        test "#{user} : cannot #{action}" do
          variable = instance_variable_get("@#{user}")

          sign_in variable

          instance_exec(&block) if block
        end
      end
    end
  end


  #Policy Test Helper
  #
  #Usage:
  #
  #allows_access(@root, @partner, :create)
  #denies_access(@partner_admin, @partner, :update)
  #permitted_records(@partner_admin, Partner)

  def allows_access(user, object, action)
    klass  = object.is_a?(Class) ? object : object.class
    policy = "#{klass}Policy".constantize

    policy.new(user, object).send("#{action}?")
  end

  def denies_access(user, object, action)
    !allows_access(user, object, action)
  end

  def permitted_records(user, klass)
    scope = "#{klass}Policy::Scope".constantize
    scope.new(user, klass).resolve&.to_a
  end

end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

# Create the default site.
# Required for all tests that navigate to a URL without a subdomain.
# Assumptions:
#   FactoryBot is available.
# Returns:
#   The default site just created.
def create_default_site
  create(:site, slug: 'default-site')
end

Geocoder.configure(lookup: :test, ip_lookup: :test)

# Geocoder returns hash with string keys, not symbols
Geocoder::Lookup::Test.add_stub(
  'M15 5DD', [
    {
      "postcode" => "M15 5DD",
      "quality" => 1,
      "eastings" => 383417,
      "northings" =>  395997,
      "country" => "England",
      "nhs_ha" => "North West",
      "longitude" => -2.251226,
      "latitude" => 53.460456,
      "european_electoral_region" => "North West",
      "primary_care_trust" => "Manchester Teaching",
      "region" => "North West",
      "lsoa" => "Manchester 019A",
      "msoa" => "Manchester 019",
      "incode" => "5DD",
      "outcode" => "M15",
      "parliamentary_constituency" => "Manchester Central",
      "admin_district" => "Manchester",
      "parish" => "Manchester, unparished area",
      "admin_county" => nil,
      "admin_ward" => "Hulme",
      "ced" => nil,
      "ccg" => "NHS Manchester",
      "nuts" => "Manchester",
      "codes" => {
         "admin_district" => "E08000003",
         "admin_county" => "E99999999",
         "admin_ward" => "E05011368",
         "parish" => "E43000157",
         "parliamentary_constituency" => "E14000807",
         "ccg" => "E38000217",
         "ccg_id" => "14L",
         "ced" => "E99999999",
         "nuts" => "UKD33"
      }
    }
  ]
)
