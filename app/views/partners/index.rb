# frozen_string_literal: true

class Views::Partners::Index < Views::Base
  prop :partners, ActiveRecord::Relation, reader: :private
  prop :site, Site, reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :selected_category, _Nilable(String), reader: :private
  prop :selected_neighbourhood, _Nilable(String), reader: :private
  prop :page, Integer, default: 1, reader: :private
  prop :total_pages, Integer, default: 1, reader: :private
  prop :page_letter_ranges, Array, default: -> { [] }, reader: :private
  prop :filter_params, Hash, default: -> { {} }, reader: :private

  def view_template
    content_for(:title) { 'Partners' }
    content_for(:image) { site.og_image }
    content_for(:description) { site.og_description }

    Hero('Our Partners', site.tagline)
    turbo_frame_tag 'partner_previews' do
      div(class: 'c c--lg-space-after') do
        Breadcrumb(trail: [['Partners', partners_path]], site_name: site.name) do
          PartnerFilter(
            site: site,
            selected_category: selected_category,
            selected_neighbourhood: selected_neighbourhood
          )
        end

        hr

        render_paginator if show_paginator?
        render_letter_grouped_partners
        render_paginator if show_paginator?
      end
      div(id: 'map') do
        Map(points: map, site: site.slug)
      end
    end
  end

  private

  def show_paginator?
    total_pages > 1
  end

  def render_paginator
    PartnersPaginator(
      page_letter_ranges: page_letter_ranges,
      current_page: page,
      filter_params: filter_params
    )
  end

  def render_letter_grouped_partners
    grouped = partners.group_by { |p| p.name[0].upcase }
    grouped.each do |letter, letter_partners|
      h3(id: "letter-#{letter}", class: 'partners-letter-heading') { letter }
      ul(class: 'partners reset two-col', id: "partners-#{letter}") do
        letter_partners.each do |partner|
          PartnerPreview(partner: partner, site: site)
        end
      end
    end
  end
end
