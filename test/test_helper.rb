require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
