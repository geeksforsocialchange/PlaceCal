# frozen_string_literal: true

require 'test_helper'

class AdminSitesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:root)
  end

  test 'create a site through the admin page' do
    host! 'admin.lvh.me'
    # TODO: add capybara so we can get this junk working
  end
end
