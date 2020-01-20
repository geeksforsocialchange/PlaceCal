# frozen_string_literal: true

require 'test_helper'

class PartnerPolicyTest < ActiveSupport::TestCase
  setup do
    @citizen = create(:citizen)
    @root = create(:root)

    @partner_admin = create(:partner_admin)
    @partner = @partner_admin.partners.first

    @partner_admin_two = create(:partner_admin)
    @partner_two = @partner_admin_two.partners.first

    @neighbourhood_admin = create(:neighbourhood_admin)
    @neighbourhood_admin.neighbourhoods << @partner.address.neighbourhood
  end

  #  Everyone except guess can view list
  def test_index
    assert denies_access(@citizen, Partner, :index)

    assert allows_access(@partner_admin, Partner, :index)
    assert allows_access(@root, Partner, :index)
  end

  #  Root admins can create
  #  Everyone else can't create
  def test_create
    assert denies_access(@citizen, Partner, :create)
    assert denies_access(@partner_admin, Partner, :create)

    assert allows_access(@root, Partner, :create)
    assert allows_access(@neighbourhood_admin, Partner, :create)
  end

  #  Partner admin, root admin can update
  #  Different partner admin, guest can't
  def test_update
    assert denies_access(@citizen, @partner, :update)
    assert denies_access(@partner_admin_two, @partner, :update)

    assert allows_access(@root, @partner, :update)
    assert allows_access(@partner_admin, @partner, :update)
    assert allows_access(@neighbourhood_admin, @partner, :update)
  end

  # Root and neighbourhood admin only can destroy

  def test_destroy
    assert denies_access(@citizen, @partner, :destroy)
    assert denies_access(@partner_admin, @partner, :destroy)

    assert allows_access(@root, @partner, :destroy)
    assert allows_access(@neighbourhood_admin, @partner, :destroy)
  end

  def test_scope
    assert_equal(permitted_records(@root, Partner), [@partner, @partner_two])
    assert_equal(permitted_records(@partner_admin, Partner), [@partner])
    assert_equal(permitted_records(@partner_admin_two, Partner), [@partner_two])
    assert_equal(permitted_records(@neighbourhood_admin, Partner), [@partner, @partner_two])
  end
end
