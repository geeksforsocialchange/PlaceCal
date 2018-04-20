require 'test_helper'

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
  end

  test 'should get index' do
    get partners_url
    assert_response :success
  end

  test 'should show partner' do
    get partner_url(@partner)
    assert_response :success
  end
end
