require 'simplecov'
SimpleCov.start 'rails' unless ENV['NO_COVERAGE']

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  def self.it_requires_authentication_for_superadmin(action, method, &block)
    test 'requires authentication' do
      instance_exec(&block) if block
      assert_redirected_to root_path
    end
  end

  def self.it_requires_authentication_for_admin(action, method, &block)
    test 'requires authentication' do
      instance_exec(&block) if block
      assert_redirected_to admin_root_path
    end
  end

  def self.it_allows_root_to_access(action, method, &block)
    test "root: should #{action} #{method}" do
      sign_in create(:root)
      instance_exec(&block) if block
      assert_response :success
    end
  end


  def self.it_allows_admin_to_access(action, method, &block)
    test "admin: should #{action} #{method}" do
      sign_in create(:admin)
      instance_exec(&block) if block
      assert_response :success
    end
  end

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

  def self.it_denies_access_to_non_admin(action, method, &block)
    test "non-admin: can't #{action} #{method}" do
       sign_in create(:user)
       instance_exec(&block) if block
       assert_redirected_to admin_root_path
    end
  end

end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
