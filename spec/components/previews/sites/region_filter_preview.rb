# frozen_string_literal: true

class Sites::RegionFilterPreview < Lookbook::Preview
  # @label Above a listing
  # @notes Only renders for a site with two or more Partnership tags; "All" is selected here.
  def listing
    render Components::Sites::RegionFilter.new(tags: [Tag.new(name: "North", slug: "north"), Tag.new(name: "South", slug: "south")])
  end

  # @label In the site menu
  def nav
    render Components::Sites::RegionFilter.new(tags: [Tag.new(name: "North", slug: "north"), Tag.new(name: "South", slug: "south")],
                                               embedded: true)
  end
end
