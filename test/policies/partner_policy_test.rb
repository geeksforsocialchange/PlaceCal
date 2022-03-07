# frozen_string_literal: true

require 'test_helper'

class PartnerPolicyTest < ActiveSupport::TestCase
  setup do
    # Make some user accounts
    # -----------------------
    @citizen = create(:citizen)
  
    @correct_partner_admin = create(:partner_admin)
    @wrong_partner_admin = create(:partner_admin)

    @correct_ward_admin = create(:citizen)
    @wrong_ward_admin = create(:citizen)

    @correct_district_admin = create(:citizen)
    @wrong_district_admin = create(:citizen)

    # @correct_region_admin = create(:neighbourhood_region_admin)
    # @wrong_region_admin = create(:neighbourhood_region_admin)

    @root = create(:root)

    ## Set up partner we want to test for and make sure it's in the right regions
    # ---------------------------------------------------------------------------
    
    @partner = @correct_partner_admin.partners.first
    @correct_ward_admin.neighbourhoods << @partner.address.neighbourhood
    @correct_district_admin.neighbourhoods << @partner.address.neighbourhood.district

    # parent = @partner.address.neighbourhood.parent
    # puts "A: Partner address ward parental ID: #{parent.id}; Child ID: #{@partner.address.neighbourhood.id}"
    # is_childed = parent.children.map(&:subtree).flatten.include?(@partner.address.neighbourhood)
    # puts "A: Partner address ward parent contains ward: #{is_childed}"

    # parent = @partner.address.neighbourhood.parent
    # puts "B: Partner address ward parental ID: #{parent.id}; Child ID: #{@partner.address.neighbourhood.id}"
    # is_childed = parent.children.map(&:subtree).flatten.include?(@partner.address.neighbourhood)
    # puts "B: Partner address ward parent contains ward: #{is_childed}"
    
    # @multi_admin = create(:neighbourhood_admin)
    # @multi_admin.neighbourhoods << @partner.address.neighbourhood

    # @ashton_partner = create(:ashton_partner)
    # @multi_admin.partners << @ashton_partner
  end

  #  Everyone except guess can view list
  def test_index    
    assert denies_access(@citizen, Partner, :index)

    assert allows_access(@root, Partner, :index)
    assert allows_access(@correct_partner_admin, Partner, :index)
    assert allows_access(@correct_ward_admin, Partner, :index)
    assert allows_access(@correct_district_admin, Partner, :index)

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
    # assert allows_access(@correct_district_admin, @partner, :update)

    # assert allows_access(@multi_admin, @partner, :update)
    # assert allows_access(@multi_admin, @partner_two, :update)
    # assert allows_access(@multi_admin, @ashton_partner, :update)
  end

  # Root and neighbourhood admin only can destroy

  def test_destroy
    assert denies_access(@citizen, @partner, :destroy)
    assert denies_access(@correct_partner_admin, @partner, :destroy)
    # assert denies_access(@multi_admin, @ashton_partner, :destroy)

    assert allows_access(@root, @partner, :destroy)
    assert allows_access(@correct_ward_admin, @partner, :destroy)
    # assert allows_access(@correct_district_admin, @partner, :destroy)

    # assert allows_access(@multi_admin, @partner, :destroy)
    # assert allows_access(@multi_admin, @partner_two, :destroy)
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
    partner = create(:partner)

    # denies user with no partners
    assert denies_access(user, partner, :update)
    
    # can update partners user has access to
    user.partners << partner
    assert allows_access(user, partner, :update)
  end
end

class TestPartnerScope < ActiveSupport::TestCase
  setup do
    @other_neighbourhood = neighbourhoods(:two)

    @normal_user = create(:citizen)
    @partner = create(:partner)
  end

  test "returns nothing" do
    assert permitted_records(@normal_user, Partner) == []
  end

  test "scope on ownership" do # test_scope_for_ownership
    @partner.users << @normal_user

    partner_2 = create(:partner, address: create(:address, neighbourhood: @other_neighbourhood))
    partner_2.users << @normal_user

    partner_3 = create(:partner, address: create(:address, neighbourhood: @other_neighbourhood))
    partner_3.users << @normal_user

    found_partners = permitted_records(@normal_user, Partner)
    assert found_partners.count == 3
  end

  test "scope on address" do # test_scope_for_address
    neighbourhood = neighbourhoods(:one)
    @normal_user.neighbourhoods << neighbourhood

    @partner.address.neighbourhood = neighbourhood

    partner_2 = create(:partner, address: create(:address, neighbourhood: neighbourhood))
    partner_3 = create(:partner, address: create(:address, neighbourhood: neighbourhood))
    partner_4 = create(:partner, address: create(:address, neighbourhood: neighbourhood))

    found_partners = permitted_records(@normal_user, Partner)
    assert found_partners.count == 4
  end

  test "scope on service areas" do # test_scope_for_service_areas
    neighbourhood = neighbourhoods(:one)
    @normal_user.neighbourhoods << neighbourhood

    @partner.service_areas.create neighbourhood: neighbourhood

    4.times do
      partner = build(:partner, address: nil)
      partner.service_areas.build neighbourhood: neighbourhood
      partner.save!
    end

    found_partners = permitted_records(@normal_user, Partner)
    assert found_partners.count == 5
  end
end

