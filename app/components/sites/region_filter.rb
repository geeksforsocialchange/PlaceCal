# frozen_string_literal: true

# Segmented control of "All" plus the site's Partnership tags (#3368 D7).
#
# The region filter is a generic partnership-tag filter: the list comes from
# the site's own tags, so adding a region is admin config rather than code.
# Selection travels in the URL as ?region=<tag slug> (D19) and is carried by
# links rather than session state (D20). Only rendered when a site has more
# than one Partnership tag.
class Components::Sites::RegionFilter < Components::Base
  prop :tags, Array, default: -> { [] }
  prop :selected, _Nilable(::Tag), default: nil
  # True when rendered as a nav item (Components::Navigation) rather than as its own block above a listing.
  prop :embedded, _Boolean, default: false

  theme_scope :region_filter,
              parts: { root: 'The row of region options, each a pill. The variant says whether it sits in the site menu or above a listing.' },
              variants: { root: %i[nav listing] },
              tokens: %i[]

  def view_template
    return if @tags.size < 2

    nav(**part(:root, variant: @embedded ? :nav : :listing, class: ('mb-4' unless @embedded), aria: { label: t('region_filter.label') })) do
      UI::Cluster(as: :ul, gap: :sm) do
        render_option(nil, t('region_filter.all'))
        @tags.each { |tag| render_option(tag, tag.name) }
      end
    end
  end

  private

  def render_option(tag, label)
    li { UI::Pill(variant: :segment, selected: active?(tag), href: href_for(tag)) { label } }
  end

  def active?(tag)
    tag.nil? ? @selected.nil? : @selected&.id == tag.id
  end

  # Preserve every other filter in the URL, replacing only the region.
  def href_for(tag)
    query = request.query_parameters.except('region', 'page')
    query = query.merge('region' => tag.slug) if tag
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end
end
