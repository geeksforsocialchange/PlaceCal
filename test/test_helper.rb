require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Usage:
  #
  # it_allows_access_to_action_for(%i[root turf_admin partner_admin place_admin citizen guest]) do
  # end

  [:index, :show, :new, :edit, :create, :update, :destroy].each do |action|
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
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
