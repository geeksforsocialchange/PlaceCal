# frozen_string_literal: true

require 'test_helper'

class UsersLogInGoToAdminSiteTest < ActionDispatch::IntegrationTest

  include Capybara::DSL
  include Capybara::Minitest::Assertions

  setup do
    @root = create(:root)
    create_default_site
  end

  test 'logging in takes user to admin site' do
    visit 'http://lvh.me/users/sign_in'

    fill_in 'Email', with: @root.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    # has redirected to admin site
    assert_equal 'http://admin.lvh.me/', current_url
  end
end
