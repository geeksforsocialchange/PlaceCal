# frozen_string_literal: true

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  setup do
    VCR.use_cassette(:import_test_calendar) do
      @calendar = create(:calendar)
    end

    @event_data = {
      dtend: DateTime.now + 1.day,
      is_active: true,
      address: create(:address),
      partner: create(:partner),
      raw_location_from_source: \
        'Unformatted Address,' \
        'Ungeolocated Lane,' \
        'Manchester'
    }
  end

  test 'ensure validation fails for duplicate event model' do
    event_hash = { summary: 'Mom and Pops Pet Store',
                   dtstart: DateTime.now - 1.hour,
                   calendar: @calendar,
                   **@event_data }

    assert Event.new(event_hash).save
    assert_not_predicate Event.new(event_hash), :valid?

    assert_raises ActiveRecord::RecordInvalid do
      Event.new(event_hash).save!
    end
  end

  test 'can create two events with the same start date and calendar but diff summary' do
    event_hash = { dtstart: DateTime.now - 1.hour, calendar: @calendar, **@event_data }
    a = Event.new(summary: 'cycling triathalon', **event_hash)
    assert a.save

    b = Event.new(summary: 'foonlys get together :,)', **event_hash)
    assert_predicate b, :valid?
  end

  test 'can create two events with the same summary and calendar but diff start' do
    event_hash = { summary: 'Harolds composure', calendar: @calendar, **@event_data }
    a = Event.new(dtstart: DateTime.now - 1.hour, **event_hash)
    assert a.save

    b = Event.new(dtstart: DateTime.now - 3.hours, **event_hash)
    assert_predicate b, :valid?
  end

  test 'can create two events with the same summary and dtstart but diff calendar' do
    event_hash = { summary: 'Harolds composure', dtstart: DateTime.now - 1.hour, **@event_data }
    a = Event.new(calendar: @calendar, **event_hash)
    assert a.save

    VCR.use_cassette(:eventbrite_events) do # , allow_playback_repeats: true) do
      b = Event.new(calendar: create(:calendar_for_eventbrite), **event_hash)
      assert_predicate b, :valid?
    end
  end

  test 'has blank location with no addresses at all' do
    event = Event.new

    assert_equal '', event.location, 'expected event location to be blank'
  end

  test 'has location pulled from its own address' do
    address = create(:address)
    event = Event.new(address: address)

    wanted = '123 Moss Ln E, Manchester, Manchester, M15 5DD'
    assert_equal wanted, event.location
  end

  test 'uses partners address if it has partner' do
    partner = create(:partner, address: create(:moss_side_address))
    event = Event.new(partner: partner, dtstart: Time.now)

    wanted = '42 Alexandra Rd, Moss Side, Manchester, M16 7BA'
    assert_equal wanted, event.location
  end

  test 'prioritises events address over partners address' do
    partner = create(:partner, address: create(:moss_side_address))
    address = create(:address)
    event = Event.new(address: address, partner: partner)

    wanted = '123 Moss Ln E, Manchester, Manchester, M15 5DD'
    assert_equal wanted, event.location
  end

  test 'ensure find_by_day returns items from current day and not from the past or future' do
    partner = create(:partner, address: create(:moss_side_address))
    yesterday = Date.today.midnight - 1.day
    today = Date.today.midnight
    tomorrow = Date.today.midnight + 1.day

    start_date = today + 12.hours
    end_date = start_date + 1.hour

    VCR.use_cassette(:calendar_events_test, allow_playback_repeats: true) do
      create_list(:event, 5, partner: partner, dtstart: yesterday + 12.hours, dtend: yesterday + 13.hours, calendar: @calendar)
      create_list(:event, 5, partner: partner, dtstart: tomorrow + 12.hours, dtend: tomorrow + 13.hours, calendar: @calendar)

      todays_event = create(:event, partner: partner, dtstart: start_date, dtend: end_date, calendar: @calendar)

      events = Event.all.find_by_day(Date.today)

      assert_equal(1, events.length)
      assert_equal events.first.dtstart, todays_event.dtstart
    end
  end

  test 'ensure find_by_day returns items from two-day events' do
    # Instances where the dtend is on the same day that we are looking
    partner = create(:partner, address: create(:moss_side_address))
    yesterday = Date.today.midnight - 1.day
    today = Date.today.midnight

    start_date = yesterday + 12.hours
    end_date = today + 12.hours

    VCR.use_cassette(:calendar_events_test, allow_playback_repeats: true) do
      create_list(:event, 5, partner: partner, dtstart: yesterday, dtend: yesterday + 1.hour, calendar: @calendar)
      todays_event = create(:event, partner: partner, dtstart: start_date, dtend: end_date, calendar: @calendar)

      events = Event.all.find_by_day(Date.today)

      assert_equal(1, events.length)
      assert_equal events.first.dtstart, todays_event.dtstart
    end
  end

  test 'ensure find_by_day returns items from multi-day events' do
    partner = create(:partner, address: create(:moss_side_address))
    yesterday = Date.today.midnight - 1.day
    tomorrow = Date.today.midnight + 1.day

    start_date = yesterday + 12.hours
    end_date = tomorrow + 12.hours

    VCR.use_cassette(:calendar_events_test, allow_playback_repeats: true) do
      create_list(:event, 5, partner: partner, dtstart: yesterday, dtend: yesterday + 1.hour, calendar: @calendar)
      tomorrows_event = create(:event, partner: partner, dtstart: start_date, dtend: end_date, calendar: @calendar)

      events = Event.all.find_by_day(Date.today)

      assert_equal(1, events.length)
      assert_equal events.first.dtstart, tomorrows_event.dtstart
    end
  end

  test 'events.for_site for neighbourhood site returns events belonging to site partners AND happening at site partners locations' do
    site_address = create(:moss_side_address)

    site = create(:site_local)
    site.neighbourhoods << site_address.neighbourhood
    site.save!

    partner = create(:partner)
    partner.address.neighbourhood = site_address.neighbourhood
    partner.save!

    partner_outside_site = create(:partner, address: create(:ashton_address))

    event_not_on_site = create(:event, dtstart: Time.now, calendar: @calendar)

    partner_creator_event = create(:event, dtstart: Time.now, calendar: @calendar)
    partner_creator_event.partner = partner
    partner_creator_event.save!

    event_in_neighbourhood = create(:event, dtstart: Time.now, calendar: @calendar)
    event_in_neighbourhood.address = create(:address, postcode: site_address.postcode)
    event_in_neighbourhood.partner = partner_outside_site
    event_in_neighbourhood.save!

    assert_equal 3, Event.count
    assert_equal [partner_creator_event, event_in_neighbourhood].sort, Event.for_site(site).sort
  end

  test 'events.for_site for partnership site returns events belonging to site partners AND happening at site partners locations' do
    site_address = create(:moss_side_address)

    tag = create(:partnership)
    site = create(:site)
    site.neighbourhoods << site_address.neighbourhood
    site.tags << tag
    site.save!

    partner = create(:partner)
    partner.address = site_address
    partner.address.neighbourhood = site_address.neighbourhood
    partner.tags << tag
    partner.save!

    partner_outside_site = create(:partner, address: create(:ashton_address))

    event_not_on_site = create(:event, dtstart: Time.now, calendar: @calendar)

    partner_creator_event = create(:event, dtstart: Time.now, calendar: @calendar)
    partner_creator_event.partner = partner
    partner_creator_event.save!

    event_in_neighbourhood = create(:event, dtstart: Time.now, calendar: @calendar)
    event_in_neighbourhood.address = create(:address, postcode: site_address.postcode)
    event_in_neighbourhood.partner = partner_outside_site
    event_in_neighbourhood.save!

    partner_assigned_event = create(:event, dtstart: Time.now, calendar: @calendar)
    partner_assigned_event.address = create(:address, postcode: site_address.postcode, street_address: partner.name)
    partner_assigned_event.partner = partner_outside_site
    partner_assigned_event.save!

    assert_equal 4, Event.count
    assert_equal [partner_creator_event, partner_assigned_event].sort, Event.for_site(site).sort
  end
end
