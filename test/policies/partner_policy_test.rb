# frozen_string_literal: true

require 'test_helper'

class PartnerPolicyTest < ActiveSupport::TestCase
  setup do
    # Make some user accounts
    # -----------------------
    @citizen = create(:citizen)
    @other_partner = create(:partner)

    @correct_partner_admin = create(:partner_admin)
    @wrong_partner_admin = create(:partner_admin)

    @correct_ward_admin = create(:citizen)
    @wrong_ward_admin = create(:citizen)

    @correct_service_area_admin = create(:neighbourhood_admin)

    @correct_district_admin = create(:citizen)
    @wrong_district_admin = create(:citizen)

    @root = create(:root)

    partnership_tag = create(:partnership)

    @wrong_partner = @wrong_partner_admin.partners.first
    @partner = @correct_partner_admin.partners.first

    @wrong_partner.address = create(:moss_side_address)
    @wrong_partner.save

    @partner.tags << partnership_tag
    @partner.service_areas.create! neighbourhood: @correct_service_area_admin.neighbourhoods.first

    @correct_ward_admin.neighbourhoods << @partner.address.neighbourhood
    @correct_district_admin.neighbourhoods << @partner.address.neighbourhood.district

    @only_ward_admin = create(:citizen)
    @only_ward_admin_partner = create(:partner)
    @only_ward_admin.neighbourhoods << @partner.address.neighbourhood

    @partnership_admin = create(:citizen)
    @partnership_admin.neighbourhoods << @partner.address.neighbourhood
    @partnership_admin.tags << partnership_tag
  end

  #  Everyone except guess can view list
  def test_index
    assert denies_access(@citizen, Partner, :index)

    assert allows_access(@root, Partner, :index)
    assert allows_access(@correct_partner_admin, Partner, :index)
    assert allows_access(@correct_ward_admin, Partner, :index)
    assert allows_access(@correct_service_area_admin, Partner, :index)
    assert allows_access(@correct_district_admin, Partner, :index)
    assert allows_access(@correct_district_admin, Partner, :index)
    assert allows_access(@partnership_admin, Partner, :index)

    # assert allows_access(@multi_admin, Partner, :index)
  end

  #  Root admins can create
  #  Everyone else can't create
  def test_create
    assert denies_access(@citizen, Partner, :create)
    assert denies_access(@correct_partner_admin, Partner, :create)

    assert allows_access(@root, Partner, :create)
    assert allows_access(@correct_ward_admin, Partner, :create)
    assert allows_access(@correct_district_admin, Partner, :create)

    # assert allows_access(@multi_admin, Partner, :create)
  end

  #  Partner admin, root admin can update
  #  Different partner admin, guest can't
  def test_update
    assert denies_access(@citizen, @partner, :update)
    assert denies_access(@wrong_partner_admin, @partner, :update)

    assert allows_access(@root, @partner, :update)
    assert allows_access(@correct_partner_admin, @partner, :update)
    assert allows_access(@correct_ward_admin, @partner, :update)
    assert allows_access(@partnership_admin, @partner, :update)
    # assert allows_access(@correct_district_admin, @partner, :update)

    # assert allows_access(@multi_admin, @partner, :update)
    # assert allows_access(@multi_admin, @partner_two, :update)
    # assert allows_access(@multi_admin, @ashton_partner, :update)
  end

  # Root and neighbourhood admin only can destroy

  def test_destroy
    assert denies_access(@citizen, @partner, :destroy)
    assert allows_access(@root, @partner, :destroy)
    assert denies_access(@correct_ward_admin, @partner, :destroy)
    assert allows_access(@only_ward_admin, @only_ward_admin_partner, :destroy)
    assert allows_access(@correct_partner_admin, @partner, :destroy)
  end

  def test_scope
    # We sort these because for some reason permitted records sometimes returns results back in a different order here
    assert_equal(permitted_records(@root, Partner).sort_by(&:id),
                 [@partner, @only_ward_admin_partner, @other_partner, @wrong_partner].sort_by(&:id))
    assert_equal(permitted_records(@correct_partner_admin, Partner).sort_by(&:id),
                 [@partner])
    assert_equal(permitted_records(@wrong_partner_admin, Partner).sort_by(&:id),
                 [@wrong_partner])
    assert_equal(permitted_records(@correct_ward_admin, Partner).sort_by(&:id),
                 [@partner, @only_ward_admin_partner, @other_partner].sort_by(&:id))
    # assert_equal(permitted_records(@correct_district_admin, Partner).sort_by(&:id),
    #              [@partner, @only_ward_admin_partner, @other_partner].sort_by(&:id))
    assert_equal(permitted_records(@partnership_admin, Partner).sort_by(&:id),
                 [@partner])
  end

  def test_create_with_partner_permissions
    user = create(:user)

    # user with no partners
    assert denies_access(user, Partner, :create)

    neighbourhood = create(:neighbourhood)
    user.neighbourhoods << neighbourhood

    # can create partners if user has neighbourhoods
    assert allows_access(user, Partner, :create)
  end

  def test_update_with_partner_permissions
    user = create(:user)

    # denies user with no partners
    assert denies_access(user, @other_partner, :update)

    # can update partners user has access to
    user.partners << @other_partner
    assert allows_access(user, @other_partner, :update)
  end
end
