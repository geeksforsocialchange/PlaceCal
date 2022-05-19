# frozen_string_literal: true

require 'test_helper'

class Admin::CalendarsTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @partner_admin = create(:partner_admin)

    @partner = @partner_admin.partners.first
    @partner_two = create(:ashton_partner)
    @neighbourhood = @partner.address.neighbourhood
    @neighbourhood_admin.neighbourhoods << @neighbourhood

    @calendar = create(:calendar, partner: @partner, place: @partner)
    host! 'admin.lvh.me'
  end

  test "root user : can get index" do
    sign_in @root
    get admin_calendars_path
    assert_select 'title', text: "Calendars | PlaceCal Admin"
    assert_select 'tbody tr', count: 1
  end

  test "neighbourhood admin : can get index" do
    sign_in @root
    get admin_calendars_path
    assert_select 'tbody tr', count: 1
  end

  # GET new
  test "root : can get new" do
    sign_in @root

    get new_admin_calendar_path

    assert_select 'title', text: "New Calendar | PlaceCal Admin"

    assert_select 'select#calendar_partner_id' do
      assert_select 'option', count: 3
    end

    assert_select 'option[disabled="disabled"]', '(No Partner)', count: 1
    assert_select 'option', @partner.name, count: 1
    assert_select 'option', @partner_two.name, count: 1
  end

  # GET new
  test "root : can get new with preselected partner" do
    @root.partners << @partner

    sign_in @root
    get new_admin_calendar_path(partner_id: @partner.id)

    assert_select 'option[selected="selected"]', @partner.name
  end

  test "neighbourhood_admin : can get new" do
    sign_in @neighbourhood_admin

    get new_admin_calendar_path


    assert_select 'select#calendar_partner_id' do
      assert_select 'option', count: 2
    end

    assert_select 'option', @partner.name, count: 1
  end

  test "partner_admin : can get new" do
    sign_in @partner_admin

    get new_admin_calendar_path

    assert_select 'select#calendar_partner_id' do
      assert_select 'option', count: 2
    end

    assert_select 'option', @partner.name, count: 1
  end

  # GET edit
  test "root : can get edit" do
    sign_in @root

    get edit_admin_calendar_path(@calendar)

    assert_select 'select#calendar_partner_id' do
      assert_select 'option', count: 3
    end

    assert_select 'option[selected="selected"]', @partner.name
    assert_select 'option', @partner_two.name, count: 1
  end

  test "neighbourhood_admin : can get edit" do
    sign_in @neighbourhood_admin

    get edit_admin_calendar_path(@calendar)

    assert_select 'select#calendar_partner_id' do
      assert_select 'option', count: 2
    end

    assert_select 'option', @partner.name, count: 1
  end

  test "partner_admin : can get edit" do
    sign_in @partner_admin

    get edit_admin_calendar_path(@calendar)

    assert_select 'select#calendar_partner_id' do
      assert_select 'option', count: 2
    end

    assert_select 'option', @partner.name, count: 1
  end

  test "partner : can see which importer is selected" do
    @calendar.update! importer_mode: 'ical'

    sign_in @partner_admin
    get edit_admin_calendar_path(@calendar)

    assert_select 'option[value="ical"][selected="selected"]', nil, count: 1
  end

  test "partner : can change importer" do
    sign_in @partner_admin

    params = { calendar: @calendar.attributes }
    params[:calendar]['importer_mode'] = 'eventbrite'

    put admin_calendar_path(@calendar), params: params

    @calendar.reload
    assert_equal 'eventbrite', @calendar.importer_mode
  end

end
