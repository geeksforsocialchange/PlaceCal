require 'test_helper'

class SuperadminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    @root = create(:root)
  end

  it_allows_access_to_index_for(%i[root]) do
    get superadmin_partners_url
  end

  it_allows_access_to_show_for(%i[root]) do
    get superadmin_partner_url(@partner)
  end

  it_allows_access_to_new_for(%i[root]) do
    get new_superadmin_partner_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Partner.count') do
      post superadmin_partners_url,
        params: { partner: { name: 'Test Partner' } }
    end
  end

  it_allows_access_to_update_for(%i[root]) do
    patch superadmin_partner_url(@partner),
      params: { partner: { name: 'New Test Partner Name' } }
  end

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Partner.count', -1) do
      delete superadmin_partner_url(@partner)
    end
  end
end
