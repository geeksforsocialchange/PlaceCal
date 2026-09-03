# frozen_string_literal: true

# The public region filter (#3368 D7).
#
# A "region" is just a Partnership tag on the current Site, so adding one to a
# site is admin config rather than code. Selection travels in the URL as
# ?region=<tag slug> (D19) and is carried by links rather than session state
# (D20) - see ApplicationController#sub_site_navigation.
module RegionFilterable
  extend ActiveSupport::Concern

  # Exposed to views so theme homepage views (rendered with only `site:`)
  # can render the region filter without re-deriving the selection.
  included do
    helper_method :region_tags, :current_region, :region_filter?
  end

  private

  # @return [Array<Tag>] the site's Partnership tags in name order; empty for
  #   the nationwide directory, which has no Site
  def region_tags
    @region_tags ||= current_site ? current_site.tags.where(type: 'Partnership').order(:name).to_a : []
  end

  # Whether the filter is worth offering: only when there is more than one
  # region to choose between. Components::RegionFilter applies this rule itself,
  # so callers pass region_tags unconditionally; this predicate is for views
  # that wrap the filter in their own markup and need to know first.
  #
  # @return [Boolean]
  def region_filter?
    region_tags.size > 1
  end

  # The Partnership tag named by ?region=<slug>. An unknown slug is ignored
  # (the page renders unfiltered) rather than raising.
  #
  # @return [Tag, nil]
  def current_region
    @current_region ||= region_tags.find { |tag| tag.slug == params[:region] } if params[:region].present?
  end
end
