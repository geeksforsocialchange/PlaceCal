require 'test_helper'

class SuperadminUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @root = create(:root)
  end

  it_allows_access_to_index_for(%i[root]) do
    get superadmin_users_url
  end

  it_allows_access_to_show_for(%i[root]) do
    get superadmin_user_url(@user)
  end

  it_allows_access_to_new_for(%i[root]) do
    get new_superadmin_user_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('User.count') do
      post superadmin_users_url,
        params: { user: attributes_for(:user) }
    end
  end

  it_allows_access_to_update_for(%i[root]) do
    patch superadmin_user_url(@user),
      params: { user: attributes_for(:user) }
  end

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('User.count', -1) do
      delete superadmin_user_url(@user)
    end
  end
end
