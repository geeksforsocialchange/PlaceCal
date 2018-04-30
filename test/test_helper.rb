require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # TODO: make all tests default to :get?

  # Usage:
  #
  # it_allows_access_to(%i[root turf_admin partner_admin place_admin citizen guest], :new) do
  # end

  # Can a Root User access this action?
  def self.it_allows_root_to_access(action, method, &block)
    test "root: should #{action} #{method}" do
      sign_in create(:root)
      instance_exec(&block) if block
      assert_response :success
    end
  end

  # Can a User that is assigned to a controlling Turf access this action?
  def self.it_allows_turf_admin_to_access(action, method, &block)
    test "turf admin: should #{action} #{method}" do
      sign_in create(:turf_admin)
      instance_exec(&block) if block
      assert_response :success
    end
  end

  # Can a User that is assigned to a controlling Partner access this action?
  def self.it_allows_partner_admin_to_access(action, method, &block)
    test "partner admin: should #{action} #{method}" do
      sign_in create(:partner_admin)
      instance_exec(&block) if block
      assert_response :success
    end
  end

  # Can a User that is assigned to a controlling Place access this action?
  def self.it_allows_place_admin_to_access(action, method, &block)
    test "place admin: should #{action} #{method}" do
      sign_in create(:place_admin)
      instance_exec(&block) if block
      assert_response :success
    end
  end

  # Can a non-root non-admin user *not* access this action?
  def self.it_denies_access_to_non_root(action, method, &block)
    test "non-root: can't#{action} #{method}" do
       sign_in create(:user)
       instance_exec(&block) if block
       assert_redirected_to root_path
    end
    test "admin: can't #{action} #{method}" do
      sign_in create(:admin)
      instance_exec(&block) if block
      assert_redirected_to root_path
    end
  end

  private

  def user_roles
    %i[root turf_admin partner_admin place_admin citizen guest]
  end

end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
