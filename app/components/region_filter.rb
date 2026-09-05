# frozen_string_literal: true

# Segmented control of "All" plus the site's Partnership tags (#3368 D7).
#
# The region filter is a generic partnership-tag filter: the list comes from
# the site's own tags, so adding a region is admin config rather than code.
# Selection travels in the URL as ?region=<tag slug> (D19) and is carried by
# links rather than session state (D20). Only rendered when a site has more
# than one Partnership tag.
class Components::RegionFilter < Components::Base
  prop :tags, Array, default: -> { [] }
  prop :selected, _Nilable(::Tag), default: nil

  def view_template
    return if @tags.size < 2

    nav(class: 'region-filter mb-4', aria: { label: t('region_filter.label') }) do
      ul(class: 'reset flex flex-wrap items-center gap-2') do
        render_option(nil, t('region_filter.all'))
        @tags.each { |tag| render_option(tag, tag.name) }
      end
    end
  end

  private

  def render_option(tag, label)
    active = active?(tag)
    li do
      link_to(label, href_for(tag),
              class: option_classes(active),
              aria: { current: (active ? 'page' : nil) })
    end
  end

  def active?(tag)
    tag.nil? ? @selected.nil? : @selected&.id == tag.id
  end

  def option_classes(active)
    [
      'with-no-sass inline-flex items-center rounded-full border px-3 py-1 text-detail no-underline',
      (active ? 'bg-primary text-background border-primary font-bold' : 'bg-background text-foreground border-rules hover:bg-tertiary')
    ].join(' ')
  end

  # Preserve every other filter in the URL, replacing only the region.
  def href_for(tag)
    query = request.query_parameters.except('region', 'page')
    query = query.merge('region' => tag.slug) if tag
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end
end
