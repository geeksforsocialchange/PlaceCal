# frozen_string_literal: true

require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  setup do
    VCR.use_cassette(:bad_meetup_gateway, record: :new_episodes) do
      @collection = create(:collection)
    end
  end

  test 'return named route if there' do
    assert_equal '/named-route', @collection.named_route
    @collection.update(route: '')
    assert_equal "/collections/#{@collection.id}", @collection.named_route
  end
end
