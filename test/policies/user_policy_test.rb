# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @citizen = create(:citizen)
    @root = create(:root)
    @partner_admin_in_partnership = create(:partner_admin)
    @partner_admin_in_neighbourhood = create(:partner_admin)
    @partner_admin = create(:partner_admin)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @partnership_tag = create(:partnership)

    @partnership_admin = create(:neighbourhood_admin)
    @partnership_admin.tags << @partnership_tag

    @partner_admin_in_partnership.partners.first.tags << @partnership_tag
    @partner_admin_in_partnership.partners.first.service_areas.create(
      neighbourhood:  @partnership_admin.neighbourhoods.first
    )
    @partner_admin_in_partnership.save!

    @partner_admin_in_neighbourhood.partners.first.address.neighbourhood = @neighbourhood_admin.neighbourhoods.first
    @partner_admin_in_neighbourhood.partners.first.save!
  end

  def test_scope
    assert_empty(permitted_records(@citizen, User))
    assert_equal(permitted_records(@root, User), User.all)
    assert_equal(permitted_records(@partnership_admin, User), [@partner_admin_in_partnership])
    assert_equal(permitted_records(@neighbourhood_admin, User), [@partner_admin_in_neighbourhood])
  end
end
