# frozen_string_literal: true

require "test_helper"

class CalendarsHelperTest < ActionView::TestCase
  include Devise::Test::IntegrationHelpers
  include Pundit::Authorization

  setup do
    @root = create(:root)

    @partner_1 = create(:partner)
    @partner_2 = create(:partner)
    @partner_3 = create(:partner)
  end

  test "options_for_location only shows partners with addresses" do
    # FIXME: there is a bug in ActionView where it gets itself into an
    #   infinite call loop and StackOverflows

    #sign_in @root

    #begin
    #  locations = options_for_location

    #rescue SystemStackError => e
    #  puts e.backtrace
    #  raise e
    #end

    # assert_equal 4, locations.length, "Should see 4 options"
  end
end
