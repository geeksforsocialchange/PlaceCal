# frozen_string_literal: true

require 'simplecov'
require 'vcr'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

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

  # Usage:
  #
  # it_allows_access_to_action_for(%i[root turf_admin partner_admin place_admin citizen guest]) do
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
    scope.new(user, klass).resolve
  end

end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
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
