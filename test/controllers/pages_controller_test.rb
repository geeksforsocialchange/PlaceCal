require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  test "should get join page" do
    get join_url
    assert_response :success
  end

  test "should get bus page" do
    get bus_url
    assert_response :success
  end

  test "should get privacy page" do
    get privacy_url
    assert_response :success
  end
end
