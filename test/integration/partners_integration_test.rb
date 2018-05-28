# frozen_string_literal: true

require 'test_helper'

class PartnersIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
  end

  test 'should show basic information' do
    get partner_url(@partner)
    assert_select 'h1', @partner.name
    assert_select 'p', @partner.short_description
    assert_select 'p', /123 Moss Ln E/
    assert_select 'p', /Manchester/
    assert_select 'p', /M15 5DD/
    assert_select 'p', /#{@partner.public_phone}/
    assert_select 'a[href=?]', "mailto:#{@partner.public_email}"
    assert_select 'a[href=?]', @partner.url
  end
end
