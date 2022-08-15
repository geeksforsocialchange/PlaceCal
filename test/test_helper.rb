# frozen_string_literal: true

# require 'simplecov'
require 'vcr'
# SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

require 'webmock/minitest'
# require 'minitest-rails'
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
include JsonMatchers::Minitest::Assertions

require "capybara/rails"
require "capybara/minitest"

Dir.glob(File.join(Rails.root, 'test/support/**/*.rb')) do |path|
  require path
end

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize(workers: :number_of_processors)

    fixtures :neighbourhoods

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

    # Policy Test Helper
    #
    # Usage:
    #
    # allows_access(@root, @partner, :create)
    # denies_access(@partner_admin, @partner, :update)
    # permitted_records(@partner_admin, Partner)

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
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
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
    { 'postcode' => 'M15 5DD',
      'quality' => 1,
      'eastings' => 383_417,
      'northings' =>  395_997,
      'country' => 'England',
      'nhs_ha' => 'North West',
      'longitude' => -2.251226,
      'latitude' => 53.460456,
      'european_electoral_region' => 'North West',
      'primary_care_trust' => 'Manchester Teaching',
      'region' => 'North West',
      'lsoa' => 'Manchester 019A',
      'msoa' => 'Manchester 019',
      'incode' => '5DD',
      'outcode' => 'M15',
      'parliamentary_constituency' => 'Manchester Central',
      'admin_district' => 'Manchester',
      'parish' => 'Manchester, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Hulme',
      'ced' => nil,
      'ccg' => 'NHS Manchester',
      'nuts' => 'Manchester',
      'codes' => {
        'admin_district' => 'E08000003',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05011368',
        'parish' => 'E43000157',
        'parliamentary_constituency' => 'E14000807',
        'ccg' => 'E38000217',
        'ccg_id' => '14L',
        'ced' => 'E99999999',
        'nuts' => 'UKD33'
      } }
  ]
)

Geocoder::Lookup::Test.add_stub(
  'OL6 8BH', [
    { 'postcode' => 'OL6 8BH',
      'quality' => 1,
      'eastings' => 394_989,
      'northings' => 401_394,
      'country' => 'England',
      'nhs_ha' => 'North West',
      'longitude' => -2.077027,
      'latitude' => 53.509207,
      'european_electoral_region' => 'North West',
      'primary_care_trust' => 'Tameside and Glossop',
      'region' => 'North West',
      'lsoa' => 'Tameside 002A',
      'msoa' => 'Tameside 002',
      'incode' => '8BH',
      'outcode' => 'OL6',
      'parliamentary_constituency' => 'Ashton-under-Lyne',
      'admin_district' => 'Tameside',
      'parish' => 'Tameside, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Ashton Hurst',
      'ced' => nil,
      'ccg' => 'NHS Tameside and Glossop',
      'nuts' => 'Greater Manchester South East',
      'codes' => {
        'admin_district' => 'E08000008',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05000800',
        'parish' => 'E43000162',
        'parliamentary_constituency' => 'E14000537',
        'ccg' => 'E38000182',
        'ccg_id' => '01Y',
        'ced' => 'E99999999',
        'nuts' => 'UKD35'
      } }
  ]
)

# this compliments the neighbourhood fixture in test/fixtures/neighbourhood.yml
Geocoder::Lookup::Test.add_stub(
  'M16 7BA', [
    {
      'postcode' => 'M16 7BA',
      'quality' => 1,
      'eastings' => 383321,
      'northings' => 395843,
      'country' => 'England',
      'nhs_ha' => 'North West',
      'longitude' => -2.252664,
      'latitude' => 53.459069,
      'european_electoral_region' => 'North West',
      'primary_care_trust' => 'Manchester Teaching',
      'region' => 'North West',
      'lsoa' => 'Manchester 024B',
      'msoa' => 'Manchester 024',
      'incode' => '7BA',
      'outcode' => 'M16',
      'parliamentary_constituency' => 'Manchester Central',
      'admin_district' => 'Manchester',
      'parish' => 'Manchester, unparished area',
      'admin_county' => nil,
      'admin_ward' => 'Moss Side',
      'ced' => nil,
      'ccg' => 'NHS Manchester',
      'nuts' => 'Manchester',
      'codes' => {
        'admin_district' => 'E08000003',
        'admin_county' => 'E99999999',
        'admin_ward' => 'E05011372',
        'parish' => 'E43000157',
        'parliamentary_constituency' => 'E14000807',
        'ccg' => 'E38000217',
        'ccg_id' => '14L',
        'ced' => 'E99999999',
        'nuts' => 'TLD33',
        'lsoa' => 'E01005243',
        'msoa' => 'E02001068',
        'lau2' => 'E08000003'
      }
    }
  ]
)

# Some helpers for working with JS and Capybara

def click_sidebar(href)
  # I think the icons are interfering with click_link
  within '.sidebar-sticky' do
    link = page.find(:css, "a[href*='#{href}']")
    visit link['href']
  end
end

def await_datatables(time = 15)
  page.find(:css, '#datatable_info', wait: time)
end

def await_select2(time = 30)
  page.all(:css, '.select2-container', wait: time)
end

def select2_node(stable_identifier)
  within ".#{stable_identifier}" do
    find(:css, '.select2-container')
  end
end

def all_cocoon_select2_nodes(css_class)
  within ".#{css_class}" do
    all(:css, '.select2-container')
  end
end

def assert_select2_single(option, node)
  within :xpath, node.path do
    assert_selector '.select2-selection__rendered', text: option
  end
end

def assert_select2_multiple(options_array, node)
  # The data is stored like this.
  # "×Computer Access\n×Free WiFi\n×GM Systems Changers"
  # The order is unpredictable so we can't build version from our options to test against
  # instead copy the data, then pull out the options and joining characters
  # If we are left with nothing then the options and stored data match
  within :xpath, node.path do
    assert_selector '.select2-selection__choice', count: options_array.length
    rendered = find(:css, '.select2-selection__rendered').text.gsub('×', '').gsub("\n", '')
    options_array.each do |opt|
      rendered = rendered.gsub(opt, '')
    end
    assert_equal('', rendered, "'#{rendered}' is in the selected data but not in the options passed to this test")
  end
end

# GraphQL helpers

def assert_field_equals(obj, key, value: nil)
  assert obj.key?(key), "field '#{key}' is missing"

  error_msg = "Field '#{key}' has incorrect value: wanted '#{value}', but got '#{obj[key]}'"

  # This is super awkward and horrible. Basically if both parameters ending up at assert_equal are nil,
  # it throws a deprecation warning:
  # DEPRECATED: Use assert_nil if expecting nil from (here). This will fail in Minitest 6.
  # So instead of being able to do
  #   assert_equal value, obj[key], error_msg
  # we have to do this super-awkward if statement mix :(

  if value
    assert_equal value, obj[key], error_msg
  else
    assert_nil obj[key], error_msg
  end
rescue Minitest::Assertion => e
  # ugh- we need to see the line that actually caused the problem here and not
  # just the above assertion line
  puts e.backtrace[2]
  raise e
end

def assert_field(obj, key, message = nil)
  message ||= "Field '#{key}' doesn't exist / is nil in: #{obj}"
  assert obj.key?(key), message # obj.key? returns false if an item is nil, ergo...

  obj[key]
end

def refute_field(obj, key, message = nil)
  message ||= "Field '#{key}' exists in: #{obj}"
  refute obj.key?(key), message # obj.key? returns false if an item is nil, ergo...

  obj[key]
end

def suppress_stdout
  stdout = $stdout
  $stdout = File.open(File::NULL, 'w')
  yield
  $stdout = stdout
end

def from_site_slug(site, path)
  host = Rails.application.routes.default_url_options[:host]
  "http://#{site.slug}.#{host}/#{path}"
end
