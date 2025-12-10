# frozen_string_literal: true

require 'test_helper'

class UsersLoginOnSiteTest < ActionDispatch::IntegrationTest
  setup do
    create_default_site
  end

  test 'redirects to base site' do
    get 'http://default-site.lvh.me/users/sign_in'

    assert_redirected_to 'http://lvh.me/users/sign_in'
  end
end
