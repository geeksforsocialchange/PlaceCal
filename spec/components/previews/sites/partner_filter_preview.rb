# frozen_string_literal: true

class Sites::PartnerFilterPreview < Lookbook::Preview
  # Category and neighbourhood dropdowns with sample counts, as on a local site's partners page.
  # @label Default
  def default
    render Components::Sites::PartnerFilter.new(site:, query: SampleQuery.new(site:))
  end

  # A category is selected, so the reset link shows.
  # @label Filtered
  def filtered
    render Components::Sites::PartnerFilter.new(site:, query: SampleQuery.new(site:), selected_category: "1")
  end

  private

  def site
    Site.new(id: 0, name: "Millbrook Community Calendar", slug: "millbrook")
  end

  Option = Data.define(:id, :name)

  # Canned facets in place of the database queries the real filter runs.
  class SampleQuery < PartnersQuery
    def call(**) = Partner.none

    def categories_with_counts(**)
      [["Arts & Culture", 12], ["Health & Wellbeing", 8], ["Community Events", 5]]
        .each_with_index.map { |(name, count), i| { category: Option.new(id: i + 1, name:), count: } }
    end

    def neighbourhoods_with_counts(**)
      [["Riverside", 9], ["Oldtown", 6]].each_with_index.map { |(name, count), i| { neighbourhood: Option.new(id: i + 1, name:), count: } }
    end
  end
end
