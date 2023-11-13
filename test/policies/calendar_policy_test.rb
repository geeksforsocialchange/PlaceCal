# frozen_string_literal: true

require 'test_helper'

class CalendarPolicyTest < ActiveSupport::TestCase
  setup do
    @partner_admin = create(:partner_admin)
    @partner_in_neighbourhood = @partner_admin.partners.first

    @other_partner_admin = create(:partner_admin)
    @partner_servicing_neighbourhood = @other_partner_admin.partners.first
    @partner_servicing_neighbourhood.address.neighbourhood = create(:neighbourhood)
    @partner_servicing_neighbourhood.service_areas.create! neighbourhood: create(:ashton_neighbourhood)
    @partner_servicing_neighbourhood.save!

    @neighbourhood_admin = create(:neighbourhood_admin)
    @neighbourhood_admin.neighbourhoods = [@partner_in_neighbourhood.address.neighbourhood]
    @neighbourhood_admin.neighbourhoods << @partner_servicing_neighbourhood.service_areas.first.neighbourhood

    @partner_outside_neighbourhood = create(:partner)
    @partner_outside_neighbourhood.address.neighbourhood = create(:neighbourhood)
    @partner_outside_neighbourhood.save!

    @root = create(:root)

    VCR.use_cassette(:import_test_calendar) do
      @neighbourhood_cal = create(:calendar)
      @partner_in_neighbourhood.calendars = [@neighbourhood_cal]
    end
    VCR.use_cassette(:calendar_for_outlook) do
      @outside_neighbourhood_cal = create(:calendar_for_outlook)
      @partner_outside_neighbourhood.calendars = [@outside_neighbourhood_cal]
    end
    VCR.use_cassette(:eventbrite_events) do
      @servicing_neighbourhood_cal = create(:calendar_for_eventbrite)
      @partner_servicing_neighbourhood.calendars = [@servicing_neighbourhood_cal]
    end
  end

  def test_scope
    # root can access everything
    assert_equal(
      permitted_records(@root, Calendar).sort,
      [@neighbourhood_cal, @outside_neighbourhood_cal, @servicing_neighbourhood_cal].sort
    )
    # neighbourhood admin can see calendars for partners with service areas and addresses in neighbourhood
    assert_equal(
      permitted_records(@neighbourhood_admin, Calendar).sort,
      [@neighbourhood_cal, @servicing_neighbourhood_cal].sort
    )
    # partner admin can only see calendars for partners they admin for
    assert_equal(permitted_records(@partner_admin, Calendar), [@neighbourhood_cal])
    assert_equal(
      permitted_records(@other_partner_admin, Calendar), [@servicing_neighbourhood_cal]
    )
  end
end
