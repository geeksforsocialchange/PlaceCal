require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collection = create(:collection)
  end

  test 'should show collection' do
    get collection_url(@collection)
    assert_response :success
  end
end
