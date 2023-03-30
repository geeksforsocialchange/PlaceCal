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

require 'capybara/rails'
require 'capybara/minitest'

Dir.glob(File.join(Rails.root, 'test/support/**/*.rb')).sort.each do |path|
  require path
end

module ActiveSupport
  class TestCase
    setup do
      Timecop.freeze(Time.zone.local(2022, 11, 8))
    end

    teardown do
      Timecop.return
    end

    include FactoryBot::Syntax::Methods

    # if you enable parallelized tests you cannot do a timing sweep
    # with `rails test -v` (which is useful for finding slow tests)
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
  assert_not obj.key?(key), message # obj.key? returns false if an item is nil, ergo...

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
  "http://#{site.slug}.#{host}#{path}"
end

def create_typed_tags
  create(:tag, name: 'free wifi', type: 'Facility')
  create(:tag, name: 'fruit ecosystem', type: 'Category')
  create(:tag, name: 'housing', type: 'Category')
  create(:tag, name: 'trans dimension', type: 'Partnership')
  create(:tag, name: 'system changers', type: 'Partnership')
end
