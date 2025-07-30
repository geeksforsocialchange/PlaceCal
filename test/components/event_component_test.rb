# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class EventComponentTest < ViewComponent::TestCase
  def test_component_renders_event_with_hero_component_for_site_context
    VCR.use_cassette(:import_test_calendar) do
      @site = create(:site_local)
      @context = :page
      @event = create(:event)
      @primary_neighbourhood = create(:neighbourhood)
      @show_neighbourhoods = false
    end
    with_request_url('/events/11234', host: "#{@site.slug}.lvh.me:3000") do
      render_inline(EventComponent.new(site: @site, context: @context, event: @event, primary_neighbourhood: @primary_neighbourhood, show_neighbourhoods: @show_neighbourhoods))
      assert_text 'N.A. (Narcotics Anonymous) - Meetup '
      assert_text '123 Moss Ln E'
      assert_text '12am –  2am'
      assert_text '2 hours'
      assert_text '9 Nov'
      assert_text 'Neighbourhood\'s Community Calendar'
    end
  end

  def test_component_renders_event_without_hero_component_for_week_context
    VCR.use_cassette(:import_test_calendar) do
      @site = create(:site_local)
      @context = :week
      @event = create(:event)
      @primary_neighbourhood = create(:neighbourhood)
      @show_neighbourhoods = false
    end
    with_request_url('/events/11234', host: "#{@site.slug}.lvh.me:3000") do
      render_inline(EventComponent.new(site: @site, context: @context, event: @event, primary_neighbourhood: @primary_neighbourhood, show_neighbourhoods: @show_neighbourhoods))
      assert_text 'N.A. (Narcotics Anonymous) - Meetup '
      assert_text '123 Moss Ln E'
      assert_text '12am –  2am'
      assert_text '2 hours'
      assert_text '9 Nov'
      assert_no_text 'Neighbourhood\'s Community Calendar'
    end
  end

  def test_component_renders_district_badge_zoom_level
    VCR.use_cassette(:import_test_calendar) do
      @site = create(:site, badge_zoom_level: 'district')
      @context = :week
      @event = create(:event)
      @primary_neighbourhood = create(:neighbourhood)
      @show_neighbourhoods = true
    end
    with_request_url('/events/11234', host: "#{@site.slug}.lvh.me:3000") do
      render_inline(EventComponent.new(site: @site, context: @context, event: @event, primary_neighbourhood: @primary_neighbourhood, show_neighbourhoods: @show_neighbourhoods))
      assert_text 'N.A. (Narcotics Anonymous) - Meetup '
      assert_text '123 Moss Ln E'
      assert_text '12am –  2am'
      assert_text '2 hours'
      assert_text '9 Nov'
      assert_text 'Manchester'
    end
  end

  def test_component_renders_ward_badge_zoom_level
    VCR.use_cassette(:import_test_calendar) do
      @site = create(:site, badge_zoom_level: 'ward')
      @context = :week
      @event = create(:event)
      @primary_neighbourhood = create(:neighbourhood)
      @show_neighbourhoods = true
    end
    with_request_url('/events/11234', host: "#{@site.slug}.lvh.me:3000") do
      render_inline(EventComponent.new(site: @site, context: @context, event: @event, primary_neighbourhood: @primary_neighbourhood, show_neighbourhoods: @show_neighbourhoods))
      assert_text 'N.A. (Narcotics Anonymous) - Meetup '
      assert_text '123 Moss Ln E'
      assert_text '12am –  2am'
      assert_text '2 hours'
      assert_text '9 Nov'
      assert_text 'Hulme'
    end
  end

  def test_component_renders_without_ward_when_show_neigbourhoods_is_false
    VCR.use_cassette(:import_test_calendar) do
      @site = create(:site, badge_zoom_level: 'ward')
      @context = :week
      @event = create(:event)
      @primary_neighbourhood = create(:neighbourhood)
      @show_neighbourhoods = false
    end
    with_request_url('/events/11234', host: "#{@site.slug}.lvh.me:3000") do
      render_inline(EventComponent.new(site: @site, context: @context, event: @event, primary_neighbourhood: @primary_neighbourhood, show_neighbourhoods: @show_neighbourhoods))
      assert_text 'N.A. (Narcotics Anonymous) - Meetup '
      assert_text '123 Moss Ln E'
      assert_text '12am –  2am'
      assert_text '2 hours'
      assert_text '9 Nov'
      assert_no_text 'Hulme'
    end
  end
end
