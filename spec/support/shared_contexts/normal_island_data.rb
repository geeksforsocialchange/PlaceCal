# frozen_string_literal: true

# Builds a representative Normal Island dataset for specs that need
# realistic page content (visual regression, integration tests, etc.)
#
# Creates: sites (published + themed), partners with addresses,
# calendars, events, tags, and neighbourhoods.
RSpec.shared_context "normal island data" do # rubocop:disable RSpec/MultipleMemoizedHelpers
  # Sites
  let!(:default_site) { create(:default_site) }
  let!(:millbrook_site) { create(:millbrook_site, is_published: true) }
  let!(:ashdale_site) { create(:ashdale_site, is_published: true) }
  let!(:coastshire_site) { create(:coastshire_site, is_published: true) }

  # Tags
  let!(:partnership_tag) { create(:partnership, name: "Millbrook Together") }
  let!(:category_tag) { create(:category, name: "Community Events") }

  # Partnership site (needs a tag to show on find-placecal)
  let!(:partnership_site) do
    ashdale_site.tap { |s| s.tags << partnership_tag }
  end

  # Partners (spread across different wards)
  let!(:riverside_hub) { create(:riverside_community_hub) }
  let!(:oldtown_library) { create(:oldtown_library) }
  let!(:greenfield_youth) { create(:greenfield_youth_centre) }
  let!(:harbourside_arts) { create(:harbourside_arts_centre) }

  # Calendars
  let!(:riverside_calendar) { create(:calendar, partner: riverside_hub) }
  let!(:library_calendar) { create(:calendar, partner: oldtown_library) }

  # Events (multiple so index pages have content)
  let!(:event_one) { create(:event, partner: riverside_hub, calendar: riverside_calendar, summary: "Community Coffee Morning") }
  let!(:event_two) { create(:event, partner: riverside_hub, calendar: riverside_calendar, summary: "Riverside Yoga Class") }
  let!(:event_three) { create(:event, partner: oldtown_library, calendar: library_calendar, summary: "Book Club Meeting") }

  # Link partner to themed site's neighbourhood
  before do
    riverside_hub.address.update!(neighbourhood: millbrook_site.neighbourhoods.first) if millbrook_site.neighbourhoods.any?
  end
end

RSpec.configure do |config|
  config.include_context "normal island data", :normal_island_data
end
