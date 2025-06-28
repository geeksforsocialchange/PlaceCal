# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class EventComponentTest < ViewComponent::TestCase
  setup do
    VCR.use_cassette(:import_test_calendar) do
      @site = create(:site)
      @context = 'SomeContext'
      @event = create(:event)
      @primary_neighbourhood = create(:neighbourhood)
      @show_neighbourhoods = false
    end
  end

  def test_component_renders_event_without_badge
    with_request_url('/events/11234.json', host: 'mossley.mossley.localhost') do
      test = render_inline(EventComponent.new(site: @site, context: @context, event: @event, primary_neighbourhood: @primary_neighbourhood, show_neighbourhoods: @show_neighbourhoods))
      puts test
      assert_text 'N.A. (Narcotics Anonymous) - Meetup 1'
      assert_text '123 Moss Ln E'
      assert_text '12am –  2am'
      assert_text '2 hours'
      assert_text '9 Nov'
    end
  end
end
