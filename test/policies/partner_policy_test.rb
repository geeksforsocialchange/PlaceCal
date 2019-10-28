# frozen_string_literal: true

require 'test_helper'

class PartnerPolicyTest < ActiveSupport::TestCase
  setup do
    @guest = create(:user)
    @root = create(:root)

    @partner = create(:partner)
    @partner_admin = create(:partner_admin, partner_ids: [@partner.id])

    @partner_two = create(:partner)
    @partner_admin_two = create(:partner_admin, partner_ids: [@partner_two.id])

    @turf = @partner.turfs.first
    @turf_admin = create(:turf_admin, turf_ids: [@turf.id])

  end

  # Everyone except guess can view list
  def test_index
    assert denies_access(@guest, Partner, :index)

    assert allows_access(@root, Partner, :index)
    assert allows_access(@turf_admin, Partner, :index)
    assert allows_access(@partner_admin, Partner, :index)
  end
  #
  #
  #   Root admins can create
  #   Everyone else can't create
  def test_create
    assert denies_access(@guest, Partner.new, :create)
    assert denies_access(@partner_admin, Partner.new, :create)

    assert allows_access(@root, Partner.new, :create)
    assert allows_access(@turf_admin, Partner.new, :create)
  end
  #
  #   Partner admin, root admin can update
  #   Different partner admin, guest can't
  def test_update
    assert denies_access(@guest, @partner, :update)
    assert denies_access(@partner_admin_two, @partner, :update)

    assert allows_access(@root, @partner, :update)
    assert allows_access(@turf_admin, @partner, :update)
    assert allows_access(@partner_admin, @partner, :update)
  end
  #
  # def test_destroy
  #   Root admin only can destroy
  # end

  def test_scope
    assert_equal(PartnerPolicy::Scope.new(@root, Partner).resolve, [@partner, @partner_two])
    assert_equal(PartnerPolicy::Scope.new(@partner_admin, Partner).resolve, [@partner])
    assert_equal(PartnerPolicy::Scope.new(@partner_admin_two, Partner).resolve, [@partner_two])
    assert_equal(PartnerPolicy::Scope.new(@turf_admin, Partner).resolve, [@partner])
  end
end
