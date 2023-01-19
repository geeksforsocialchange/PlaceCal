# frozen_string_literal: true

require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    VCR.use_cassette(:import_test_calendar, allow_playback_repeats: true) do
      neighbourhoods = create_list(:neighbourhood, 3)
      date = DateTime.now.beginning_of_day

      # Deliberately saving address twice. (create + save) Second time overwrites neighbourhood.
      addresses = neighbourhoods.map do |n|
        a = create(:address)
        a.neighbourhood = n
        a.save
        a
      end

      @calendar = create(:calendar)

      @events = addresses.map do |a|
        e = build(:event, address: a, dtstart: date, dtend: date + 1.hour, calendar: @calendar)
        e.save
        e
      end

      @slugless_site = create_default_site

      @default_site = create(:site)
      @default_site.neighbourhoods << neighbourhoods
      @default_site.save

      @site = build(:site)
      @site.neighbourhoods.append(neighbourhoods.first)
      @site.neighbourhoods.append(neighbourhoods.second)
      @site.save
    end
  end

  test 'slugless site redirects to find my placecal' do
    get events_url
    assert_response :redirect
  end

  # It looks like PlaceCal had aggregate /events functionality or something?
  # test 'should get index without subdomain' do
  #   get events_url
  #   assert_response :success
  #   assert_select "ol.events li", 3
  # end

  test 'should get index with configured subdomain' do
    get from_site_slug(@site, events_path)

    assert_response :success
    assert_select 'ol.events li', 2
  end

  test 'should get index with invalid subdomain' do
    get url_for controller: :events, subdomain: 'notaknownsubdomain'
    assert_response :redirect
  end

  test 'should show event' do
    get from_site_slug(@default_site, event_path(@events[0]))
    assert_response :success
  end

  test 'events with no location show up on index' do
    VCR.use_cassette(:eventbrite_events) do
      neighbourhood = create(:neighbourhood)
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood
      partner.save!

      calendar = create(:calendar_for_eventbrite, partner: partner, strategy: 'no_location')

      @site.neighbourhoods.destroy_all
      @site.neighbourhoods << neighbourhood

      5.times do |n|
        partner.events.create!(
          calendar: calendar,
          summary: "Event #{n}",
          description: 'A description',
          dtstart: Time.now,
          dtend: Time.now + 1.hour
        )
      end

      get from_site_slug(@site, events_path)
      assert_response :success

      events = assigns(:events).values.first
      assert_equal(5, events.length)
    end
  end

  test 'events meta descriptions contain no markup' do
    description_markdown = <<~MD
      ### Test Event heading

      Paragrpahy with [link](www.placecal.org)

      **Strong text with class**{: class=""}
    MD

    description_plain = <<~PLAIN
      Test Event heading

      Paragrpahy with link

      Strong text with class
    PLAIN

    @events[0].description = description_markdown
    @events[0].save

    get from_site_slug(@default_site, event_path(@events[0]))
    assert_response :success

    assert_select 'meta[property="og:description"]' do |element|
      assert_equal description_plain, element.attr('content').to_s
    end

    assert_select 'meta[name="twitter:description"]' do |element|
      assert_equal description_plain, element.attr('content').to_s
    end
  end
end
